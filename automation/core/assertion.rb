#
# Suraj Vijayakumar
# 26 Mar 2013
#

require 'automation/core/component'

module Automation

  # The base class for an assertion.
  class Assertion < Component

    # The failure message.
    attr_reader :message
    # The details of the failure.
    attr_reader :details

    # New assertion.
    def initialize
      super

      @message = ''
      @details = ''
    end

    # Checks this assertion. Returns true if the assertion passes. False otherwise.
    def check(*args)
      raise NotImplementedError.new("Method 'check' not implemented by '#{self.class.name}'")
    end

  end

end
