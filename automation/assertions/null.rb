#
# Suraj Vijayakumar
# 15 Apr 2013
#

require 'automation/core/assertion'

module Automation

  # An assertion that always passes.
  class SuccessAssertion < Assertion

    # New success assertion.
    #
    # @param [String] message
    # @param [String] details
    def initialize(message, details)
      super()

      @message = message
      @details = details
    end

    # Always return true.
    def check
      true
    end

  end

  # An assertion that always fails.
  class FailureAssertion < Assertion

    # New failure assertion.
    #
    # @param [String] message
    # @param [String] details
    def initialize(message, details)
      super()

      @message = message
      @details = details
    end

    # Always returns false.
    def check
      false
    end

  end

  module Assertions

    private

    # Assertion that always fails.
    #
    # @param [String] message
    # @param [String] details
    # @return [Automation::FailureAssertion] the file compare assertion.
    def failure(message = '', details = '')
      FailureAssertion.new(message, details)
    end

    # Assertion that always passes.
    #
    # @param [String] message
    # @param [String] details
    # @return [Automation::FailureAssertion] the file compare assertion.
    def success(message = '', details = '')
      SuccessAssertion.new(file)
    end

  end

end
