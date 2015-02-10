#
# Suraj Vijayakumar
# 19 Jan 2015
#

class Automation::ResultsDatabase < Automation::Database

  # Represents an application that can be tested by the framework.
  class Application < BaseModel

    # Provides accessor for all tests of a particular application.
    has_many :tests, through: :run_config, class_name: 'Automation::TestDatabase::Test'

  end

end
