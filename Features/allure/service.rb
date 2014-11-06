#
# Suraj Vijayakumar
# 03 Nov 2014
#

require 'allure-ruby-adaptor-api'

require 'automation/manager/service'

require_relative 'builder'

module Automation

  # Listens for messages from the allure observer.
  class AllureListener < Automation::Manager::Service

    # New allure listener.
    def initialize
      super

      AllureRubyAdaptorApi.configure do |c|
        c.output_dir = @config_manager['allure.output.directory']
      end

      @builder = AllureRubyAdaptorApi::Builder
      @mutex = Mutex.new

      @test_results = Hash.new { |h, k| h[k] = {} }
    end

    # Notify Allure that testing has started.
    def allure_start
      @builder.send(:init_suites)
    end

    # Notify Allure that testing has finished.
    def allure_stop
      @mutex.synchronize do
        # Generate the Allure XML report.
        @builder.build!
        # Generate the Allure HTML report off the XML report.
        @logger.info('Generating allure report...')
        allure_bat = @config_manager['tool.allure.executable']
        output_directory = @config_manager['allure.output.directory']
        args = ['generate', '-o', output_directory, output_directory]
        output, status = popen_capture(allure_bat, *args)
        @logger.fine("Allure messages\n#{output}")
        raise ExecutionError.new('Allure encountered errors.') if status.exitstatus != 0
      end
    end

    # Notify Allure that a test has started.
    #
    # @param [String] suite_name
    # @param [String] test_name
    def allure_start_test(suite_name, test_name, labels = {})
      @mutex.synchronize do
        # Start the suite if this is the first test in said suite.
        @builder.start_suite(suite_name) unless @builder.suites.has_key?(suite_name)
        # And then start the test too.
        @test_results[test_name] = {status: :passed}
        @builder.start_test(suite_name, test_name, labels)
      end
    end

    # Notify Allure that a test has finished.
    #
    # @param [String] suite_name
    # @param [String] test_name
    def allure_stop_test(suite_name, test_name)
      @mutex.synchronize do
        # Stop the test.
        @builder.stop_test(suite_name, test_name, @test_results[test_name])
        # And then stop the suite too. Each test will do this, but only the last one will be used.
        # This will generate a lot of log messages (one for each test).
        @builder.stop_suite(suite_name)
      end
    end

    # Notify Allure of a test failure.
    #
    # @param [String] test_name
    # @param [Exception] exception
    def allure_test_failed(test_name, exception)
      @mutex.synchronize do
        @test_results[test_name][:status] = :failed
        @test_results[test_name][:exception] = exception
      end
    end

    # Notify Allure that a step has started.
    #
    # @param [String] suite_name
    # @param [String] test_name
    # @param [String] step_name
    def allure_start_step(suite_name, test_name, step_name)
      @mutex.synchronize { @builder.start_step(suite_name, test_name, step_name) }
    end

    # Notify Allure that a step has finished.
    #
    # @param [String] suite_name
    # @param [String] test_name
    # @param [String] step_name
    def allure_stop_step(suite_name, test_name, step_name, status = :passed)
      @mutex.synchronize { @builder.stop_step(suite_name, test_name, step_name, status) }
    end

  end

end