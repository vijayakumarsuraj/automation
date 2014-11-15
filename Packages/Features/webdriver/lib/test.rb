#
# Suraj Vijayakumar
# 30 Oct 2014
#

require 'uri'
require 'watir-webdriver'

require 'automation/core/test'

module Automation

  module Webdriver

    # Error raised when a 'error_on_fail' step fails.
    class StepFailedError < Automation::Error
    end

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

      # Navigates to the specified page.
      #
      # @param [Automation::Webdriver::Page] page
      def navigate_to(page)
        url = [@base_url, page.path].join('')
        @logger.debug("Navigating to '#{url}'")
        @browser.goto(url)
      end

      # Opens the browser required for this test.
      def open_browser
        @logger.info("Starting browser '#{@browser_name}' #{@browser_args.inspect}...")
        @browser = Watir::Browser.new(@browser_name, *@browser_args)
        environment.save(:browser, @browser)
      end

      # Closes the browser this test had opened.
      def close_browser
        @logger.info('Closing browser...')
        @browser.close unless @browser.nil?
      end

      # Starts a new step.
      #
      # @param [String] step_name
      # @param [Proc] block
      def step(step_name, error_on_fail = true, &block)
        @current_step = step_name
        @runner.notify_change('test_step_started', step_name)
        status = yield
        @runner.notify_change('test_step_finished', step_name, status ? :passed : :failed)
        # If error on fail is true and the test failed, raise an error.
        raise StepFailedError.new("Step '#{step_name}' failed") if error_on_fail && !status
      ensure
        @current_step = nil
      end

      # Capture a screenshot of the current page.
      #
      # @param [String] caption
      def screenshot(caption)
        working_directory = @config_manager['test.working.directory']
        file = File.join(working_directory, "#{caption}.png")
        @browser.screenshot.save(file)
        @current_step.nil? ? @runner.notify_change('test_screenshot', file) : @runner.notify_change('test_step_screenshot', @current_step, file)
      end

    end

  end

end