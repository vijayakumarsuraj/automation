#
# Suraj Vijayakumar
# 30 Oct 2014
#

require 'watir-webdriver'

require 'automation/core/test'

module Automation

  module Webdriver

    class Test < Automation::Test

      # Access to the test's browser instance.
      attr_reader :b

      def initialize
        super

        @browser_name = 'firefox'
        @browser_args = []
      end

      private

      # The following steps are carried out (in no particular order):
      # 1. Open the browser.
      def before_test
        open_browser
      end

      # The following steps are carried out (in no particular order):
      # 1. Close the browser.
      def clean_test
        close_browser
      end

      def open_browser
        @logger.info("Starting browser '#{@browser_name}' #{@browser_args.inspect}...")
        @browser = Watir::Browser.new(@browser_name, *@browser_args)
      end

      def close_browser
        @logger.info('Closing browser...')
        @browser.close unless @browser.nil?
      end

      # Starts a new step.
      #
      # @param [String] step_name
      # @param [Proc] block
      def step(step_name, &block)
        @runner.notify_change('test_step_started', step_name)
        status = yield
        @runner.notify_change('test_step_finished', step_name, status ? :passed : :failed)
      end

    end

  end

end