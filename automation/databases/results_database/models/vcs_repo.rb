#
# Suraj Vijayakumar
# 29 Oct 2013
#

require 'automation/databases/results_database'

require 'automation/enums/vcs_type'

module Automation

  class ResultsDatabase < Database

    # Represents a version control system's repository.
    class VcsRepo < BaseModel

      # Custom accessors.
      include Automation::VcsTypeAccessor

    end

  end

end