#
# Suraj Vijayakumar
# 19 Jan 2015
#

class Automation::ResultsDatabase < Automation::Database

  # Represents the result of a run.
  class RunResult < BaseModel

    # Provides accessor for all the test results of this run.
    has_many :test_results, inverse_of: :run_result, dependent: :destroy, class_name: 'Automation::TestDatabase::TestResult'
    # Provides accessor for all the changes in this result.
    has_many :change_events, inverse_of: :run_result, dependent: :destroy, class_name: 'Automation::TestDatabase::ChangeEvent'

  end

end
