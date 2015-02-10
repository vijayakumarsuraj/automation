#
# Suraj Vijayakumar
# 22 Mar 2013
#

class Automation::TestDatabase < Automation::Database

  # Represents a test.
  class Test < BaseModel

    # Each test is associated with a application.
    belongs_to :run_config, inverse_of: :tests, class_name: 'Automation::ResultsDatabase::RunConfig'
    # Provides accessor for all the results for a particular test.
    has_many :test_results, inverse_of: :test
    # Provides accessor for all the changes in this test.
    has_many :change_events, inverse_of: :test

    # The 'tags' column is an array that is saved as YAML.
    serialize :tags, Array

  end

end
