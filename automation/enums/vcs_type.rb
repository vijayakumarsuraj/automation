#
# Suraj Vijayakumar
# 29 Oct 2013
#

require 'automation/core/enum'

module Automation

  # Represents a VCS type.
  class VcsType < Enum

    # Represents an SVN repository.
    SVN = create(0)
    # Represents a Git repository.
    GIT = create(1)

  end

end
