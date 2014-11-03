#
# Suraj Vijayakumar
# 20 Jul 2013
#

require 'automation/databases/results_database'

module Automation

  class ResultsDatabase < Database

    # Represents the results of a task in a run.
    class TaskResult < BaseModel

      # Each task result is associated with a run.
      belongs_to :run_result, inverse_of: :task_results
      # Each test result is associated with a test whose results it represents.
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
      include Automation::ResultAccessor
      include Automation::StatusAccessor

    end

  end

end
