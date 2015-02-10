#
# Suraj Vijayakumar
# 22 Mar 2013
#

class Automation::ResultsDatabase < Automation::Database

  # Represents a run configuration for grouping a set of runs.
  class RunConfig < BaseModel

    # Each config is associated with an application.
    belongs_to :application, inverse_of: :run_configs
    # Provides accessor for all tasks of a particular config.
    has_many :tasks, inverse_of: :run_config
    # Provides accessor for all results for a particular config.
    has_many :run_results, inverse_of: :run_config

  end

end
