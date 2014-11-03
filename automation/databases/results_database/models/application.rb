#
# Suraj Vijayakumar
# 22 Mar 2013
#

require 'automation/databases/results_database'

module Automation

  class ResultsDatabase < Database

    # Represents an application that can be tested by the framework.
    class Application < BaseModel

      # Provides accessor for all configs of a particular application.
      has_many :run_configs, inverse_of: :application
      # Provides accessor for all tests of a particular application.
      has_many :tests, through: :run_config
      # Provides accessor for all tasks of a particular application.
      has_many :tasks, through: :run_config

    end

  end

end
