#
# Suraj Vijayakumar
# 26 Mar 2013
#

require 'automation/core/component'

module Automation

  class AssertionFailedError < StandardError

    # New assertion failed error.
    #
    # @param [Automation::Assertion] assertion the assertion that failed.
    def initialize(assertion)
      super(assertion.message)

      set_backtrace(assertion.backtrace)
    end

  end

  # The base class for an assertion.
  class Assertion < Component

    # The failure message.
    attr_accessor :message
    # The backtrace of the failure - populated from the site of the failure.
    attr_accessor :backtrace

    # New assertion.
    def initialize
      super

      @message = ''
      @backtrace = ''
    end

    # Checks this assertion. Returns true if the assertion passes. False otherwise.
    def check(*args)
      raise NotImplementedError.new("Method 'check' not implemented by '#{self.class.name}'")
    end

  end

end
