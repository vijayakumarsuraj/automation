#
# Suraj Vijayakumar
# 15 Apr 2013
#

require 'test/assertions/assertion'

module Automation::Test

  # An assertion that always passes.
  class SuccessAssertion < Assertion

    # New success assertion.
    #
    # @param [String] message
    def initialize(message)
      super()

      @message = message
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
    def initialize(message)
      super()

      @message = message
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
    # @return [Automation::FailureAssertion] the file compare assertion.
    def failure(message = '')
      FailureAssertion.new(message)
    end

    # Assertion that always passes.
    #
    # @param [String] message
    # @return [Automation::FailureAssertion] the file compare assertion.
    def success(message = '')
      SuccessAssertion.new(message)
    end

  end

end
