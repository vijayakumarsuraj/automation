#
# Suraj Vijayakumar
# 13 Feb 2013
#

module Automation

  module RunResultHelpers

    # Deletes the result archive associated with the specified run.
    #
    # @param [String] run_name
    def run_result_delete_archive(run_name)
      @results_archive.delete_run_result(run_name)
    rescue
      # Ignore.
    end

    # Get an array with the change counts (added, removed, started failing, started passing, changed failures).
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    def run_result_change_counts(run_result)
      Automation::Change::ByValue.map { |change| run_result_change_count(run_result, change) }
    end

    # Returns an array of test results sorted by their result and name for the specified change.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    # @param [Automation::Change] change the change.
    def run_result_change_results(run_result, change)
      @results_database.get_test_results_with_change(run_result, change)
    end

    # Returns an array of task results sorted by their result and name.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    def run_result_task_results(run_result)
      task_results = run_result.task_results
      task_results.sort do |tr1, tr2|
        w1, w2 = tr1.result, tr2.result
        n1 = tr1.task.task_name
        n2 = tr2.task.task_name
        # First sort in descending order of weights.
        # If the weights are equal, sort in ascending order of names.
        w1 != w2 ? w2 <=> w1 : n1 <=> n2
      end
    end

    # Returns an array of test results sorted by their result and name.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    def run_result_test_results(run_result)
      test_results = run_result.test_results
      test_results.sort do |tr1, tr2|
        w1, w2 = tr1.result, tr2.result
        n1, n2 = tr1.test.test_name, tr2.test.test_name
        # First sort in descending order of weights.
        # If the weights are equal, sort in ascending order of names.
        w1 != w2 ? w2 <=> w1 : n1 <=> n2
      end
    end

    private

    # Get the number of tests with the specified change.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    # @param [Automation::Change] change
    # @return [Integer] the count.
    def run_result_change_count(run_result, change)
      ResultsDatabase::ChangeEvent.where(run_result_id: run_result, value: change.value).count
    end

  end

end