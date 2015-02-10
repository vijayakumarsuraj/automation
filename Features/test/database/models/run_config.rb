#
# Suraj Vijayakumar
# 19 Jan 2015
#

class Automation::ResultsDatabase < Automation::Database

  # Represents a run configuration for grouping a set of runs.
  class RunConfig < BaseModel

    # Provides accessor for all tests of a particular config.
    has_many :tests, inverse_of: :run_config, class_name: 'Automation::TestDatabase::Test'

  end

end
