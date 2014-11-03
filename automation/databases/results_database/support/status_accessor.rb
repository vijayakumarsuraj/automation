#
# Suraj Vijayakumar
# 20 May 2013
#

module Automation

  # Provides a custom accessor for the status column.
  module StatusAccessor

    # Updates the status of this result.
    #
    # @param [Automation::Status] new_status the new status.
    def status=(new_status)
      write_attribute(:status, new_status.value)
    end

    # Gets the status of this result.
    #
    # @return [Automation::Status] the current status.
    def status
      Automation::Status.from_value(read_attribute(:status))
    end

  end

end