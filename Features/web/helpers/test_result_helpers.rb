#
# Suraj Vijayakumar
# 15 Feb 2013
#

module Automation

  module TestResultHelpers

    # Gets a list of all changes for the specified test.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run for whose changes are required.
    # @param [Automation::TestDatabase::Test] test the test whose changes are required.
    # @return [Array<Automation::Test::Change>] an array of change objects.
    def test_changes(run_result, test)
      changes = run_result.change_events.where(test_id: test)
      # Convert the change values into Change objects and return.
      changes.sort.map { |change| Automation::Test::Change.from_value(change.value) }
    end

    # Gets a list of all changes for the specified test result.
    #
    # @param [Automation::TestDatabase::TestResult] test_result the test whose changes are required.
    # @return [Array<Automation::Test::Change>] an array of change objects.
    def test_result_changes(test_result)
      test_changes(test_result.run_result, test_result.test)
    end

    # Filter the list of test results, showing only failed tests.
    #
    # @param [Array<Automation::TestDatabase::TestResult>] test_results
    # @return [Array<Automation::TestDatabase::TestResult>]
    def test_results_filter(test_results)
      test_results.select do |tr|
        # Non TestResult items are never filtered.
        next true unless tr.kind_of?(Automation::TestDatabase::TestResult)
        entity_result(tr) != Automation::Result::Pass
      end
    end

    # Checks to see if the specified test result is a changed failure.
    #
    # @param [Automation::TestDatabase::TestResult] test_result
    # @return [Boolean] true if the test result is a changed failure, false otherwise.
    def test_result_changed_failure?(test_result)
      run_result = test_result.run_result
      test = test_result.test
      changed = run_result.change_events.where(test_id: test, value: Automation::Test::Change::TestChangedFailure.value).first

      !changed.nil?
    end

    # Checks to see if the specified test result is a new success.
    #
    # @param [Automation::TestDatabase::TestResult] test_result
    # @return [Boolean] true if the test result is a new success, false otherwise.
    def test_result_new_success?(test_result)
      run_result = test_result.run_result
      test = test_result.test
      changed = run_result.change_events.where(test_id: test, value: Automation::Test::Change::TestStartedPassing.value).first

      !changed.nil?
    end

    # Get a string that represents the type of this test.
    #
    # @param [Automation::TestDatabase::TestResult] test_result
    # @return [String] the test type.
    def test_result_test_type(test_result)
      test_test_type(test_result.test)
    end

    # Get a string that represents the type of this test.
    #
    # @param [Automation::TestDatabase::Test] test
    # @return [String] the test type.
    def test_test_type(test)
      test.type_name
    end

  end

end
