#
# Suraj Vijayakumar
# 22 Mar 2013
#

require 'automation/core/database'

module Automation

  # The results database. Stores information relating to the results of each run.
  class ResultsDatabase < Database

    require_relative 'results_database/models'

    # Removes stale rows from the following:
    # RunConfig, Task, Test, TestType and Application
    def clean
      super

      with_connection do |connection|
        connection.execute(SQL_DELETE_RUN_CONFIGS)
        connection.execute(SQL_DELETE_TASKS)
        connection.execute(SQL_DELETE_TESTS)
        connection.execute(SQL_DELETE_APPLICATIONS)
      end
    end

    # Adds a change to the specified test result.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result to update.
    # @param [Automation::ResultsDatabase::Test] test the test to update.
    # @param [Automation::Change] change the change too add.
    def add_test_result_change(run_result, test, change)
      ChangeEvent.create(value: change, run_result: run_result, test: test)
    end

    # Creates a RunResult entity for the current run.
    #
    # @param [Automation::ResultsDatabase::RunConfig] run_config the run configuration to which this result belongs.
    def create_run_result(run_config)
      run_name = @config_manager['run.name']
      RunResult.create(run_config: run_config, start_date_time: DateTime.now, run_name: run_name)
    end

    # Creates a TestResult entity for the specific test run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run this test result belongs.
    # @param [Automation::ResultsDatabase::Test] test the test.
    def create_test_result(run_result, test)
      TestResult.create(run_result: run_result, test: test, start_date_time: DateTime.now)
    end

    # Creates a TaskResult entity for the specific task run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run this task result belongs.
    # @param [Automation::ResultsDatabase::Task] task the task.
    def create_task_result(run_result, task)
      TaskResult.create(run_result: run_result, task: task, start_date_time: DateTime.now)
    end

    # Gets the next run result for the specified run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [Boolean] skip_exception if true, runs whose result is > Fail are not counted.
    # @param [Boolean] skip_non_official if true, runs whose official flag is false are not counted.
    # @return [Automation::ResultsDatabase:RunResult] the next run result.
    def get_next_run_result(run_result, skip_exception = true, skip_non_official = true)
      run_config = run_result.run_config
      run_id = run_result.id
      results = RunResult.where(run_config_id: run_config).where('id > ?', run_id)
      # Filter rows with result > failed if the skip_exception flag is true.
      failed_value = Result::Fail.value
      results = results.where('result <= ?', failed_value) if skip_exception
      results = results.where(official: true) if skip_non_official
      # The first row is the next result.
      results.first
    end

    # Gets the previous run result for the specified run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [Boolean] skip_exception if true, runs whose result is > Fail are not counted.
    # @param [Boolean] skip_non_official if true, runs whose official flag is false are not counted.
    # @return [Automation::ResultsDatabase:RunResult] the previous run result.
    def get_previous_run_result(run_result, skip_exception = true, skip_non_official = true)
      run_config = run_result.run_config
      run_id = run_result.id
      results = RunResult.where(run_config_id: run_config).where('id < ?', run_id)
      # Filter rows with result > failed if the skip_exception flag is true.
      failed_value = Result::Fail.value
      results = results.where('result <= ?', failed_value) if skip_exception
      results = results.where(official: true) if skip_non_official
      # The last row is the previous result.
      results.last
    end

    # Get the run result against which this run was compared.
    # Can return nil if such a run was not found.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    # @return [Automation::ResultsDatabase::RunResult]
    def get_analysed_against_run_result(run_result)
      analyser = get_task_results(run_result, 'analyser').first
      return nil if analyser.nil?

      find_run_result(analyser.properties['previous_run'])
    end

    # Gets a list of incomplete test results.
    #
    # @return [Array<Automation::ResultsDatabase::TestResult>] the list of test results.
    def get_running_test_results(run_result)
      running_value = Automation::Status::Running.value
      TestResult.where(run_result_id: run_result, status: running_value)
    end

    # Get the run property with the specified key. Returns 'value' if such a property does not exist.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] key the property to get.
    # @param [Object] value the default value to return if a property does not exist.
    def get_run_property(run_result, key, value = nil)
      property = RunProperty.where(run_result_id: run_result, key: key).first
      property.nil? ? value : property.value
    end

    # Get the run property with the specified key. Returns 'value' if such a property does not exist.
    # Parses the property as a YAML string and returns the generated hash.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] key the property to get.
    # @param [Object] value the default value to return if a property does not exist.
    def get_run_property_yaml(run_result, key, value = {})
      property = get_run_property(run_result, key)
      property.nil? ? value : YAML.load(property)
    end

    # Get the RunResult entity for the current run.
    #
    # @param [String] run_name the name of the run (defaults to the current run)
    # @return [Automation::ResultsDatabase::RunResult] the run result.
    def get_run_result(run_name = @config_manager['run.name'])
      RunResult.where(run_name: run_name).first
    end

    # Gets the task results for all the tasks with the specified name.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] task_name the name of the task.
    # @param [Array<Automation::ResultsDatabase::TaskResult>]
    def get_task_results(run_result, task_name)
      run_result.task_results.joins(:task).where(task: {task_name: task_name})
    end

    # Get the RunResult entity for the specified task id.
    #
    # @param [String] result_id the result id.
    # @return [Automation::ResultsDatabase::RunResult] the run result.
    def find_run_result(result_id)
      RunResult.find(result_id)
    rescue
      nil
    end

    # Get the TaskResult entity for the specified task id.
    #
    # @param [String] result_id the result id.
    # @return [Automation::ResultsDatabase::TaskResult] the task result.
    def find_task_result(result_id)
      TaskResult.find(result_id)
    rescue
      nil
    end

    # Returns the first test with the specified test name. This result is not guaranteed to be unique.
    #
    # @param [String] test_name the name fo the test
    # @return [Automation::ResultsDatabase::Test] the test.
    def get_test(test_name)
      Test.where(test_name: test_name).first
    end

    # Gets the average execution time of the last 'n' runs of the specified test.
    # Only considers tests whose results are pass, fail or warn.
    #
    # @param [String] test_name the name of the test.
    # @param [Integer] n the number of previous runs to use to calculate the average. Default is 10.
    # @param [Integer] default the default value to return if there are no previous runs. Default is 0.
    # @return [Float] the average in seconds.
    def get_test_average_time(test_name, n = 10, default = 0)
      test_pack = environment.test_pack
      configuration = test_pack.get_test_configuration(test_name)
      average = configuration['test.average_execution_time', default: nil]
      return average unless average.nil?

      test = Test.where(test_name: test_name).first
      return default if test.nil?

      running_value = Automation::Status::Running.value
      exception_value = Automation::Result::Exception.value
      test_results = test.test_results
      test_results = test_results.where('status != ? AND result < ?', running_value, exception_value)
      test_results = test_results.order('id DESC').limit(n)
      # If there are no previous results, return the default value.
      count = test_results.length
      return default if count == 0
      # Calculate average.
      total = 0
      test_results.each { |test_result| total += (test_result.end_date_time - test_result.start_date_time) }
      (total / count)
    end

    # Get the TestResult entity for the specified test result id.
    #
    # @param [String] result_id the result id.
    # @return [Automation::ResultsDatabase::TestResult] the test result.
    def find_test_result(result_id)
      TestResult.find(result_id)
    rescue
      nil
    end

    # Gets a list of test results that have the specified change.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [Automation::Change] change the change.
    # @return [Array<Automation::ResultsDatabase::TestResult>] the list of test results
    def get_test_results_with_change(run_result, change)
      changes = ChangeEvent.where(run_result_id: run_result, value: change.value)

      if change == Automation::Change::TestRemoved
        changes = changes.map { |c| Test.where(id: c.test).first }
        changes.sort { |t1, t2| t1.test_name <=> t2.test_name }
      else
        changes = changes.map { |c| TestResult.where(test_id: c.test, run_result_id: run_result).first }
        changes.sort { |tr1, tr2| tr1.test.test_name <=> tr2.test.test_name }
      end
    end

    # Get an array with the test counts (pass + warn, fail + exception + timed out + unknown, ignored).
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    def get_run_result_test_counts(run_result)
      pass_count = run_result_test_count(run_result, Automation::Result::Pass)
      warn_count = run_result_test_count(run_result, Automation::Result::Warn)
      fail_count = run_result_test_count(run_result, Automation::Result::Fail)
      exception_count = run_result_test_count(run_result, Automation::Result::Exception)
      ignored_count = run_result_test_count(run_result, Automation::Result::Ignored)
      timed_out_count = run_result_test_count(run_result, Automation::Result::TimedOut)
      unknown_count = run_result_test_count(run_result, Automation::Result::Unknown)
      # Return the counts.
      [pass_count + warn_count, fail_count + exception_count + timed_out_count + unknown_count, ignored_count]
    end

    # Gets the Application entity for the current run. Creates it if required.
    #
    # @param [String] application the name of the application.
    # @return [Automation::ResultsDatabase::Application] the application.
    def get_application!(application = @config_manager['run.application'])
      Application.where(application_name: application).first_or_create
    end

    # Get the RunConfig entity for the current run. Creates it if required.
    #
    # @return [Automation::ResultsDatabase::RunConfig] the run  config.
    # @param [String] config_name the name of the configuration.
    # @param [String] application the application.
    def get_run_config!(config_name = @config_manager['run.config_name'], application = get_application!)
      RunConfig.where(config_name: config_name, application_id: application).first_or_create
    end

    # Creates a Task entity for the specified test.
    #
    # @param [Automation::ResultsDatabase::RunConfig] run_config the run config.
    # @param [String] task_name the task name.
    def get_task!(run_config, task_name)
      task = Task.where(task_name: task_name, run_config_id: run_config).first_or_create
      task.save
      task
    rescue ActiveRecord::StatementInvalid
      Task.where(task_name: task_name, run_config_id: run_config).first
    end

    # Creates a Test entity for the specified test.
    #
    # @param [Automation::ResultsDatabase::RunConfig] run_config the run config.
    # @param [String] test_name the test name.
    # @param [String] type_name the type name.
    def get_test!(run_config, test_name, type_name)
      test = Test.where(test_name: test_name, type_name: type_name, run_config_id: run_config).first_or_create
      test.save
      test
    rescue ActiveRecord::StatementInvalid
      Test.where(test_name: test_name, type_name: type_name, run_config_id: run_config).first
    end

    # Deletes the specified run property.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    # @param [String] key
    def remove_run_property(run_result, key)
      property = RunProperty.where(run_result_id: run_result, key: key).first
      property.destroy unless property.nil?
    end

    # Sets the specified key-value pair as a property for the specified run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] key the property's key.
    # @param [String] value the property's value.
    def set_run_property(run_result, key, value)
      property = RunProperty.where(run_result_id: run_result, key: key).first_or_create(value: value)
      property.save
      property
    end

    private

    # The base model for the results database.
    def base_model
      BaseModel
    end

    # Get the number of tests with the specified result.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    # @param [Automation::Result] result
    # @return [Integer] the count.
    def run_result_test_count(run_result, result)
      results = TestResult.where(run_result_id: run_result, result: result.value)
      results = results.where { end_date_time != nil }
      results.count
    end

  end

end

#
# Miscellaneous clean-up queries.
#
SQL_DELETE_RUN_CONFIGS = <<-SQL
DELETE
FROM run_configs
WHERE id NOT IN (
  SELECT DISTINCT(run_config_id)
  FROM run_results
)
SQL

SQL_DELETE_TASKS = <<-SQL
DELETE
FROM tasks
WHERE id NOT IN (
  SELECT DISTINCT(task_id)
  FROM task_results
)
SQL

SQL_DELETE_TESTS = <<-SQL
DELETE
FROM tests
WHERE id NOT IN (
  SELECT DISTINCT(test_id)
  FROM test_results
)
SQL

SQL_DELETE_APPLICATIONS = <<-SQL
DELETE
FROM applications
WHERE id NOT IN (
  SELECT DISTINCT(application_id)
  FROM run_configs
)
SQL
