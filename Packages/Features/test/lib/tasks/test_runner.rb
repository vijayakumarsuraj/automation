#
# Suraj Vijayakumar
# 03 Jan 2013
#

require 'automation/core/task'

module Automation::Test

  # The base class for running application specific tests. Each application must provide a custom implementation of
  # this class.
  class TestRunner < Automation::Task

    # The run result entity.
    attr_reader :run_result
    # The test entity.
    attr_reader :resource
    # The test result entity.
    attr_reader :test_result
    # The test's name.
    attr_reader :test_name
    # Test test object.
    attr_reader :test

    # New test runner that will load and execute the the test specified by the test.name property.
    # The results are also persisted.
    def initialize
      super

      @test_name = @config_manager['test.name']
    end

    # Notifies all observers that the test being run has failed.
    #
    # @param [Exception] exception the exception that caused this test to fail
    def notify_test_failed(exception)
      notify_change('test_failed', exception)
    end

    # Updates the test result with the process id of the test being executed.
    #
    # @param [Integer] pid the PID.
    def update_pid(pid = $$)
      super

      @test_result.properties['target'] = "#{runtime.hostname}:#{pid}"
      @test_result.save # Save right away - this property must be visible outside this process also.
    end

    private

    # The following steps are carried out by the default test runner (in no particular order):
    # 1. Notify any listeners that this test has finished.
    # 2. Clean up the environment in which the test was executed.
    # 3. Update the results to indicate that the test has completed.
    def cleanup
      if defined? @test_result
        # Acquire a lock on the results - this is so that the TestMonitor can't update.
        @test_database.with_transaction do
          @test_result.reload
          @test_result.lock!
          # Results are saved only if the test is not already marked complete.
          # For example: this could occur when a test is killed by the test monitor.
          if @test_result.status != Automation::Status::Complete
            @test_result.result = @result
            @test_result.status = Automation::Status::Complete
            @test_result.end_date_time = DateTime.now
            @test_result.save
          end
        end
        # The 'target' property is not needed now, since the test is complete.
        @test_result.properties.delete('target')
        @test_result.save
      end
      #
      if defined? @result_data
        @result_data.close
      end
      #
      notify_change('test_finished')
      super
      #
      Logging.ndc.pop
    end

    # The following steps are carried out by the default test runner (in no particular order):
    # 1. Notify all observers that the test has failed.
    def exception(ex)
      notify_test_failed(ex)
      #
      super
    end

    # The following steps are carried out by the default test runner (in no particular order):
    # 1. Attempts to run the test. Exceptions are caught and logged - but not raised.
    def run
      heartbeat_start
      FileUtils.cd(@working_directory) { @test.start }
    rescue
      @logger.error(format_exception)
      @result = Automation::Result::Exception
    ensure
      heartbeat_stop
    end

    # The following steps are carried out by the default test runner (in no particular order):
    # 1. Load the test.
    # 2. Create the row in the results database to indicate that this test has started.
    # 3. Notify any listeners that the this test has started.
    # 4. Create the environment in which the test will be executed.
    # 5. Create results zip.
    def setup
      Logging.ndc.push(@test_name)
      #
      super
      @result_data = Automation::TaskResultData.new(@config_manager['run.result.directory'], @test_name)
      runtime.save(:test_runner, self)
      # Task name.
      @task_result.properties['display_name'] = @test_name
      @task_result.save
      #
      @logger.debug('Loading test...')
      load_test
      create_working_directory
      notify_change('test_started')
      #
      @logger.debug('Loading database resources...')
      @run_result = @results_database.get_run_result
      @run_config = @run_result.run_config
      @resource = @test_database.get_test!(@run_config, @test_name, @test.test_type)
      @test_result = @test_database.create_test_result(@run_result, @resource)
      # Validate that the resources were created properly.
      raise DataError.new("Could not create the 'Test' resource") if @resource.nil?
      raise DataError.new("Could not create the 'TestResult' resource") if @test_result.nil?
      # Save extra test information to the database.
      @resource.test_category = @test.category
      @resource.test_description = @test.description
      @resource.save
      # Save the current process' PID.
      update_pid
    end

    # The following steps are carried out by the default test runner (in no particular order):
    def shutdown
      super
    end

    # Each test is executed from a unique working directory where it cannot interfere with other test executions.
    # This will create that working directory and copy all test data into it.
    def create_working_directory
      source = @config_manager['test_pack.test_data_directory']
      destination = @working_directory = @config_manager['test.working.directory']
      # Copy all files from the source directory to the destination directory.
      FileUtils.mkdir_p(destination)
      return unless File.exist?(source)
      FileUtils.cd(source) do
        files = Dir.glob('*')
        @logger.debug("Copying #{files.length} items from '#{source}' to '#{destination}'")
        background(files, WAIT_FOR_RESULT) do |file|
          @logger.fine { "Copying '#{file}'..." }
          FileUtils.cp_r(file, destination)
        end
      end
    end

    # Starts the heartbeat for the current test. This will start a parallel thread that will send a 'heartbeat'
    # message at fixed intervals.
    def heartbeat_start
      @heart = Thread.new do
        Logging.ndc.clear
        Logging.ndc.push('heartbeat-thread')
        while true
          notify_change('test_alive')
          sleep(@config_manager['test.heartbeat.frequency'])
        end
        Logging.ndc.pop
      end
    end

    # Stops the heartbeat for the current test.
    def heartbeat_stop
      @heart.kill
    end

    # Attempts to load the required test.
    # If the test could not be loaded, an error is raised.
    def load_test
      test_pack = runtime.test_pack
      # Initialise the test.
      @test = test_pack.get_test(@test_name)
      @test.logger = @logger
      @test.runner = self
      @test.result_data = @result_data
    end

  end

end
