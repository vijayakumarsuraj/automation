#
# Suraj Vijayakumar
# 10 May 2013
#

require 'automation/core/enum'

module Automation

  # Represent a result.
  class Result < Enum

    # Gets an enum object for the specified value.
    #
    # @param [Integer] return_value the value to get an enum for.
    # @return [Result] the enum object.
    def self.from_return_value(return_value)
      # Get the saved enum reference.
      return_value.nil? ? nil : ByReturnValue[return_value]
    end

    # The return value associated with this result.
    attr_reader :return_value

    # New result.
    def initialize(value, return_value)
      super(value)

      @return_value = return_value
      ByReturnValue[@return_value] = self
    end

    # Maps result return values to result objects.
    ByReturnValue = []

    # Result type for when a task executes without any errors and returns the expected output.
    Pass = create(0, 0)
    # Result type for when a task has executed without errors, but has encountered some minor issues.
    Warn = create(1, 2)
    # Result type for when a task has executed without errors, but has returned unexpected output.
    Fail = create(2, 1)
    # Result type for when a task raises an exception.
    Exception = create(3, 3)
    # Result type for when a task is to be ignored.
    Ignored = create(4, 4)
    # Result type for when a task is timed-out.
    TimedOut = create(5, 5)
    # Result type for when the result of a task is not known.
    Unknown = create(6, 6)

  end

end