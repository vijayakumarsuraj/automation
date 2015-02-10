#
# Suraj Vijayakumar
# 21 May 2013
#

class Automation::TestDatabase < Automation::Database

  # Represents a change in the results of a test.
  class ChangeEvent < BaseModel

    # Each change is associated with a run result.
    belongs_to :run_result, inverse_of: :change_events, class_name: 'Automation::TestDatabase::Test'
    # Each change is associated with a test.
    belongs_to :test, inverse_of: :change_events

    # Custom accessors.
    include Automation::TestDatabase::ChangeAccessor

  end

end
