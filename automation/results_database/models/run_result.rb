#
# Suraj Vijayakumar
# 22 Mar 2013
#

class Automation::ResultsDatabase < Automation::Database

  # Represents a run's property.
  class RunProperty < BaseModel

    # Each property is associated with a run result.
    belongs_to :run_result, inverse_of: :run_properties

  end

  # Represents the result of a run.
  class RunResult < BaseModel

    # Each run result is associated with a config.
    belongs_to :run_config, inverse_of: :run_results
    # Provides accessor for all the task results of this run.
    has_many :task_results, inverse_of: :run_result, dependent: :destroy
    # Provides accessor for all the properties in this result.
    has_many :run_properties, inverse_of: :run_result, dependent: :destroy

    # Sets up default values.
    after_initialize :default_values

    def default_values
      self.result ||= Automation::Result::Unknown
      self.status ||= Automation::Status::Running
      self.end_date_time ||= nil
    end

    # Custom accessors.
    include Automation::ResultsDatabase::ResultAccessor
    include Automation::ResultsDatabase::StatusAccessor

    # Invalidates this run result.
    def invalidate
      self.result = Automation::Result::Ignored
      self.save
    end

  end

end
