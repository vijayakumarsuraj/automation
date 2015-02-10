#
# Suraj Vijayakumar
# 22 Mar 2013
#

class Automation::ResultsDatabase < Automation::Database

  # Represents an application that can be automated by the framework.
  class Application < BaseModel

    # Provides accessor for all configs of a particular application.
    has_many :run_configs, inverse_of: :application
    # Provides accessor for all tasks of a particular application.
    has_many :tasks, through: :run_config

  end

end
