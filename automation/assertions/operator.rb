#
# Suraj Vijayakumar
# 26 Mar 2013
#

require 'automation/core/assertion'

module Automation

  # An assertion for checking the equality of two values.
  class EqualityAssertion < Assertion

    # New equality assertion.
    #
    # @param [Object] value1
    # @param [Object] value2
    def initialize(value1, value2)
      super()

      @value1 = value1
      @value2 = value2
    end

    # Checks if value1 == value2. Returns true if the assertion passes. False otherwise.
    def check
      if @value1 == @value2
        @message = "#{@value1} == #{@value2}"
        true
      else
        @message = "#{@value1} != #{@value2}"
        false
      end
    end

  end

  # An assertion for checking if a number is within a specified range.
  class RangeAssertion < Assertion

    # New range assertion.
    #
    # @param [Numeric] number the number to validate.
    # @param [Numeric] lower the expected range.
    # @param [Numeric] upper the expected range.
    def initialize(number, lower, upper)
      super()

      @number = number
      @lower = lower
      @upper = upper
    end

    # Check if number is within the specified range. True if it is, false if isn't
    def check
      if @number >= @lower && @number <= @upper
        @message = "Number '#{@number}' is within range '#{@lower}-#{@upper}'."
        true
      else
        @message = "Number '#{@number}' is not within range '#{@lower}-#{@upper}'."
        false
      end
    end

  end

  # An assertion that negates the result of the assertion it wraps.
  class NotAssertion < Assertion

    # New range assertion.
    #
    # @param [Automation::Assertion] inner the assertion to negate.
    def initialize(inner)
      super()

      @inner = inner
    end

    # Returns the negative of the inner assertion. The message and detail are also set to
    # the value of the inner assertion.
    def check
      result = @inner.check
      @message = @inner.message

      !result
    end

  end

  class AndAssertion < Assertion

    # New and assertion.
    #
    # @param [Array<Automation::Assertion>] assertions
    def initialize(*assertions)
      @assertions = assertions
    end

    def check
      passed_assertions = []
      failed_assertions = []

      @assertions.each do |assertion|
        assertion.check ? (passed_assertions << assertion.message) : (failed_assertions << assertion.message)
      end

      if failed_assertions.length > 0
        @message = "One or more assertions failed:\n#{failed_assertions.join("\n")}"
        false
      else
        @message = "All assertions passed:\n#{passed_assertions.join("\n")}"
        true
      end
    end

  end

  class OrAssertion < Assertion

    # New or assertion.
    #
    # @param [Array<Automation::Assertion>] assertions
    def initialize(*assertions)
      @assertions = assertions
    end

    def check
      passed_assertions = []
      failed_assertions = []

      @assertions.each do |assertion|
        assertion.check ? (passed_assertions << assertion.message) : (failed_assertions << assertion.message)
      end

      if passed_assertions.length > 0
        @message = "One or more assertions passed:\n#{passed_assertions.join("\n")}"
        true
      else
        @message = "All assertions failed:\n#{failed_assertions.join("\n")}"
        false
      end
    end

  end

  # Assertions supported by the 'assert' method.
  module Assertions

    private

    # Assertion for asserting equality.
    #
    # @param [Object] value1
    # @param [Object] value2
    # @return [Automation::EqualityAssertion] the equality assertion.
    def are_equal(value1, value2)
      EqualityAssertion.new(value1, value2)
    end

    # Assertion for checking if a number is within the specified range.
    #
    # @param [Numeric] number the number to check.
    # @param [Numeric] lower the expected range.
    # @param [Numeric] upper the expected range.
    # @return [Automation::RangeAssertion] the range assertion.
    def is_within(number, lower, upper)
      RangeAssertion.new(number, lower, upper)
    end

    # Assertion for asserting negation.
    #
    # @param [Automation::Assertion] assertion the assertion negate.
    # @return [Automation::NotAssertion] the 'not' assertion.
    def not(assertion)
      NotAssertion.new(assertion)
    end

    # Assertion for logically ANDing assertions.
    #
    # @param [Array<Assertion>] assertions
    # @return [Automation::AndAssertion]
    def all(*assertions)
      AndAssertion.new(*assertions)
    end

    # Assertion for logically ORing assertions.
    #
    # @param [Array<Assertion>] assertions
    # @return [Automation::OrAssertion]
    def one(*assertions)
      OrAssertion.new(*assertions)
    end

  end

end
