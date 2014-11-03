#
# Suraj Vijayakumar
# 21 May 2013
#

module Automation

  # Provides a custom accessor for the change column.
  module ChangeAccessor

    # Updates the value of this change.
    #
    # @param [Automation::Change] new_change the new change.
    def value=(new_change)
      write_attribute(:value, new_change.value)
    end

    # Gets the value of this change.
    #
    # @return [Automation::Change] the current change.
    def status
      Automation::Change.from_value(read_attribute(:value))
    end

  end

end