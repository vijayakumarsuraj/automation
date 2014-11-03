#
# Suraj Vijayakumar
# 21 May 2013
#

require 'automation/databases/results_database'

module Automation

  class ResultsDatabase < Database

    # Represents a change in the results of a test.
    class ChangeEvent < BaseModel

      # Each change is associated with a run result.
      belongs_to :run_result, inverse_of: :change_events
      # Each change is associated with a test.
      belongs_to :test, inverse_of: :change_events

      # Custom accessors.
      include Automation::ChangeAccessor

    end

  end

end
