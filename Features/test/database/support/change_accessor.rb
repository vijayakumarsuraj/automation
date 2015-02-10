#
# Suraj Vijayakumar
# 21 May 2013
#

class Automation::TestDatabase < Automation::Database

  # Provides a custom accessor for the change column.
  module ChangeAccessor

    # Updates the value of this change.
    #
    # @param [Automation::Test::Change] new_change the new change.
    def value=(new_change)
      write_attribute(:value, new_change.value)
    end

    # Gets the value of this change.
    #
    # @return [Automation::Test::Change] the current change.
    def status
      Automation::Test::Change.from_value(read_attribute(:value))
    end

  end

end
