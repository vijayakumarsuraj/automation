#
# Suraj Vijayakumar
# 20 Jul 2013
#

class Automation::ResultsDatabase < Automation::Database

  # Represents the results of a task in a run.
  class TaskResult < BaseModel

    # Each task result is associated with a run.
    belongs_to :run_result, inverse_of: :task_results
    # Each task result is associated with a task whose results it represents.
    belongs_to :task, inverse_of: :task_results

    # The properties hash.
    serialize :properties, Hash

    # Sets up default values.
    after_initialize :default_values

    def default_values
      self.result ||= Automation::Result::Unknown
      self.status ||= Automation::Status::Running
      self.end_date_time ||= nil
      self.properties ||= {}
    end

    # Custom accessors.
    include Automation::ResultsDatabase::ResultAccessor
    include Automation::ResultsDatabase::StatusAccessor

  end

end
