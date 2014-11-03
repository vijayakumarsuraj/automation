#
# Suraj Vijayakumar
# 29 Oct 2013
#

module Automation

  # Provides a custom accessor for the vcs_type column.
  module VcsTypeAccessor

    # Updates the VCS type of this repository.
    #
    # @param [Automation::ResultsDatabase::VcsType] new_type the new type.
    def vcs_type=(new_type)
      write_attribute(:vcs_type, new_type.value)
    end

    # Gets the VCS type of this repository.
    #
    # @return [Automation::ResultsDatabase::VcsType] the current type.
    def vcs_type
      Automation::ResultsDatabase::VcsType.from_value(read_attribute(:type))
    end

  end

end