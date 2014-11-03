#
# Suraj Vijayakumar
# 20 Jul 2013
#

require 'automation/databases/results_database'

module Automation

  class ResultsDatabase < Database

    # Represents a task.
    class Task < BaseModel

      # Provides accessor for all the results for a particular task.
      has_many :task_results, inverse_of: :task

    end

  end

end
