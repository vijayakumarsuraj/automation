#
# Suraj Vijayakumar
# 17 May 2013
#

require 'automation/core/task'

module Automation::Test

  # Represents the analyser that will compare the results of the specified run with a previous similar run
  class Analyser < Automation::Task

    # New analyser.
    #
    # @param [String] run_name The name of the run to analyse.
    def initialize(run_name = runtime.config_manager['run.name'])
      super()

      @run_name = run_name
    end

    private

    # The following steps are carried out by the default analyser (in no particular order):
    # 1. Notify any listeners that this analyser has finished.
    # 2. Update and save the run result entity.
    def cleanup
      if defined? @run_result
        @run_result.status = Status::Complete
        @run_result.end_date_time = DateTime.now
        @run_result.save
      end
      #
      notify_change('analyser_finished')
      super
    end

    # The following steps are carried out by the default analyser (in no particular order):
    def run
      @logger.info('Analysing...')
      unless @previous_run_result.nil?
        @task_result.properties['previous_run'] = @previous_run_result.id
        find_added_tests
        find_removed_tests
        find_started_failing_tests
        find_started_passing_tests
      end
    end

    # The following steps are carried out by the default analyser (in no particular order):
    # 1. Notify any listeners that this analyser has started.
    # 2. Update and save the run result entity.
    def setup
      super
      notify_change('analyser_started')
      # Update the run status.
      @run_result = @results_database.get_run_result(@run_name)
      @run_result.status = Status::Analysing
      @run_result.save
      #
      @previous_run_result = @results_database.get_previous_run_result(@run_result, true, @run_result.official)
    end

    # Finds the tests that were added in this run.
    def find_added_tests
      @logger.debug('Looking for new tests...')

      previous_test_ids = @previous_run_result.test_results.map { |result| result.test_id }
      tests = @run_result.test_results

      added_tests = tests.where { |q| q.test_id.not_in previous_test_ids }
      added_tests.each do |test_result|
        @test_database.create_test_result_change(@run_result, test_result.test, Automation::Test::Change::TestAdded)
      end
    end

    # Finds the tests that were removed in this run.
    def find_removed_tests
      @logger.debug('Looking for tests that have been removed...')

      previous_tests = @previous_run_result.test_results
      test_ids = @run_result.test_results.map { |result| result.test_id }

      removed_tests = previous_tests.where { |q| q.test_id.not_in test_ids }
      removed_tests.each do |test_result|
        @test_database.create_test_result_change(@run_result, test_result.test, Automation::Test::Change::TestRemoved)
      end
    end

    # Finds the tests that have started failing in this run.
    def find_started_failing_tests
      @logger.debug('Looking for new failures...')

      failed_value = Result::Fail.value
      previous_test_ids = @previous_run_result.test_results.where { result >= failed_value }.map { |result| result.test_id }
      tests = @run_result.test_results.where { result >= failed_value }

      failed_tests = tests.where { |q| q.test_id.not_in previous_test_ids }
      failed_tests.each do |test_result|
        @test_database.create_test_result_change(@run_result, test_result.test, Automation::Test::Change::TestStartedFailing)
      end
    end

    # Finds the tests that have started passing in this run.
    def find_started_passing_tests
      @logger.debug('Looking for new successes...')

      failed_value = Result::Fail.value
      previous_test_ids = @previous_run_result.test_results.where { result < failed_value }.map { |result| result.test_id }
      tests = @run_result.test_results.where { result < failed_value }

      passed_tests = tests.where { |q| q.test_id.not_in previous_test_ids }
      passed_tests.each do |test_result|
        @test_database.create_test_result_change(@run_result, test_result.test, Automation::Test::Change::TestStartedPassing)
      end
    end

  end

end