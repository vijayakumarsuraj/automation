#
# Suraj Vijayakumar
# 30 Oct 2014
#

require 'automation/core/assertion'

module Automation

  # An assertion for checking the if a value is true.
  class TrueAssertion < Assertion

    # New true assertion.
    #
    # @param [Object] value
    def initialize(value)
      super()

      @value = value
    end

    # Checks if value is true. Returns true if the assertion passes. False otherwise.
    def check
      @message = "#{@value}"
      @value
    end

  end

  # An assertion for checking the if a value is false.
  class FalseAssertion < Assertion

    # New false assertion.
    #
    # @param [Object] value
    def initialize(value)
      super()

      @value = value
    end

    # Checks if value is false. Returns true if the assertion passes. False otherwise.
    def check
      @message = "#{@value}"
      !@value
    end

  end

  # Assertions supported by the 'assert' method.
  module Assertions

    private

    # Assertion for asserting if a value is true.
    #
    # @param [Object] value
    # @return [Automation::TrueAssertion] the true assertion.
    def is_true(value)
      TrueAssertion.new(value)
    end

    # Assertion for asserting if a value is false.
    #
    # @param [Object] value
    # @return [Automation::TrueAssertion] the false assertion.
    def is_false(value)
      FalseAssertion.new(value)
    end

  end

end
