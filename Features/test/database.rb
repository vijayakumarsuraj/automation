#
# Suraj Vijayakumar
# 19 Jan 2015
#

require 'automation/core/database'

class Automation::TestDatabase < Automation::Database

  module FindMethods

    # Get the TestResult entity for the specified test result id.
    #
    # @param [String] result_id the result id.
    # @return [Automation::ResultsDatabase::TestResult] the test result.
    def find_test_result(result_id)
      TestResult.find(result_id)
    rescue
      nil
    end

  end

  module CreateMethods

    # Creates a TestResult entity for the specific test run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run this test result belongs.
    # @param [Automation::ResultsDatabase::Test] test the test.
    def create_test_result(run_result, test)
      TestResult.create(run_result: run_result, test: test, start_date_time: DateTime.now)
    end

    # Adds a change to the specified test result.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result to update.
    # @param [Automation::ResultsDatabase::Test] test the test to update.
    # @param [Automation::Test::Change] change the change too add.
    def create_test_result_change(run_result, test, change)
      ChangeEvent.create(value: change, run_result: run_result, test: test)
    end

  end

  module GetCreateMethods

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

  end

  require_relative 'database/models'

  include FindMethods
  include CreateMethods
  include GetCreateMethods

  # Removes stale rows from the following:
  # Test
  def clean
    super

    with_connection { |connection| connection.execute(SQL_DELETE_TESTS) }
  end

  # Update the database schema to the specified version.
  #
  # @param [Integer] version the version to migrate to. If nil, migrates to the latest version.
  def migrate(version = nil)
    @logger.fine('Running test migrations...')
    super(File.join(Automation::FRAMEWORK_ROOT, Automation::FET_DIR, 'test/database/migrations'), version)
  end

  # Get the run result against which this run was compared.
  # Can return nil if such a run was not found.
  #
  # @param [Automation::ResultsDatabase::RunResult] run_result
  # @return [Automation::ResultsDatabase::RunResult]
  def get_analysed_against_run_result(run_result)
    results_database = runtime.databases.results_database
    analyser = results_database.get_task_results(run_result, 'analyser').first
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
    test_pack = runtime.test_pack
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

  # Gets a list of test results that have the specified change.
  #
  # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
  # @param [Automation::Test::Change] change the change.
  # @return [Array<Automation::ResultsDatabase::TestResult>] the list of test results
  def get_test_results_with_change(run_result, change)
    changes = ChangeEvent.where(run_result_id: run_result, value: change.value)

    if change == Automation::Test::Change::TestRemoved
      changes = changes.map { |c| Test.where(id: c.test).first }
      changes.sort { |t1, t2| t1.test_name <=> t2.test_name }
    else
      changes = changes.map { |c| TestResult.where(test_id: c.test, run_result_id: run_result).first }
      changes.sort { |tr1, tr2| tr1.test.test_name <=> tr2.test.test_name }
    end
  end

  private

  # The base model for the web database.
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

SQL_DELETE_TESTS = <<-SQL
DELETE
FROM #{SQL_TABLE_PREFIX}tests
WHERE id NOT IN (
  SELECT DISTINCT(test_id)
  FROM test_results
)
SQL
