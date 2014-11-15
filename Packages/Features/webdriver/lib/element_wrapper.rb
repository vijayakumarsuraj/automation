#
# Suraj Vijayakumar
# 31 Oct 2014
#

require 'automation/core/component'

module Automation

  module Webdriver

    module ElementWrapper

      # The underlying element that is being wrapped.
      attr_reader :element

      # Waits till the underlying element is present. Waiting at most 'timeout' number of seconds.
      # Returns the amount of time waited. May be off by upto .5 seconds.
      #
      # @param [Integer] timeout
      def wait_till_present(timeout = 30)
        Watir::Wait.until(timeout) { @element.visible? }
      end

      # Overridden to redirect to the underlying 'element'. If the element also does not support the method, raises an error.
      def method_missing_with_wrapper(symbol, *args, &block)
        @element.respond_to?(symbol) ? @element.send(symbol, *args, &block) : method_missing_without_wrapper(symbol, *args, &block)
      end

      # Checks if either this page or the underlying browser respond to a method.
      def respond_to_with_wrapper?(symbol, include_all = false)
        respond_to_without_wrapper?(symbol, include_all) || @element.respond_to?(symbol, include_all)
      end

      alias_method_chain :method_missing, :wrapper
      alias_method_chain :respond_to?, :wrapper

    end

  end

end
