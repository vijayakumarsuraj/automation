#
# Suraj Vijayakumar
# 20 Jul 2013
#

class Automation::ResultsDatabase < Automation::Database

  # Represents a task.
  class Task < BaseModel

    # Provides accessor for all the results for a particular task.
    has_many :task_results, inverse_of: :task

  end

end
