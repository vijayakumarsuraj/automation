#
# Suraj Vijayakumar
# 03 Mar 2014
#

require 'automation/manager/service'

require 'automation/support/runnable'

module Automation::Test

  # Represents the info of a particular test.
  class TestInfo

    # The exact time at which the last heartbeat was received.
    attr_reader :last_update
    # The average execution time for this test.
    attr_reader :average

    # New test info for the specified test.
    #
    # @param [String] test_name the name of the test.
    def initialize(test_name)
      @name = test_name
      @last_update = DateTime.now

      runtime = Automation::Runtime.instance
      test_database = runtime.databases['test']
      @average = test_database.with_connection { test_database.get_test_average_time(test_name, 10, 0) }
    end

    # Indicate that a heartbeat was received for this test.
    # This will update the 'last_update' value.
    def heartbeat_received
      @last_update = DateTime.now
    end

  end

  class TestMonitor < Automation::Manager::Service

    # Makes this service a runnable.
    include Automation::Runnable

    # New test monitor.
    def initialize
      super

      @tests = {}
      @mutex = Mutex.new
      @stopped = false
      @results_database = runtime.databases.results_database
      @test_database = runtime.databases['test']

      @heartbeat_timeout = service_config('heartbeat.timeout')
      @default_duration = service_config('default_duration')
      @minimum_duration = service_config('minimum_duration')
      @maximum_duration = service_config('maximum_duration')

      # Starts the test monitor on an unmanaged thread.
      Thread.new do
        Logging.ndc.clear
        Logging.ndc.push("#{@component_name}-thread")
        start
        Logging.ndc.pop
      end
    end

    # Exceptions are printed, but not propagated further.
    def exception
      @logger.warn(format_exception($!))
    end

    # Runs this test monitor (on the current thread).
    # This method will block till the 'stop' method is invoked.
    def run
      frequency = service_config('frequency')
      until @stopped
        @mutex.synchronize { @test_database.with_connection { check_running_tests } }
        sleep(frequency)
      end
    end

    # Indicate that this monitor should stop.
    # The monitor will stop after it has finished running its current iteration (or after 1 second if it was asleep)
    def stop
      @stopped = true
    end

    # Notify the monitor that a heartbeat was received.
    #
    # @param [String] test_name the name of the test.
    def test_monitor_heartbeat(test_name)
      @mutex.synchronize do
        @tests[test_name].heartbeat_received if @tests.has_key?(test_name)
      end
    end

    # Notify the monitor that a test has started.
    #
    # @param [String] test_name the name of the test.
    def test_monitor_register(test_name)
      @mutex.synchronize do
        if @tests.has_key?(test_name)
          @logger.warn("Ignoring registration attempt. '#{test_name}' already exists.")
        else
          @tests[test_name] = TestInfo.new(test_name)
          @logger.debug("Registered '#{test_name}'")
        end
      end
    end

    # Notify the monitor that a test has completed.
    #
    # @param [String] test_name the name of the test.
    def test_monitor_unregister(test_name)
      @mutex.synchronize do
        if @tests.has_key?(test_name)
          @tests.delete(test_name)
          @logger.debug("Un-registered '#{test_name}'")
        else
          @logger.warn("Ignoring un-registration attempt. '#{test_name}' does not exists.")
        end
      end
    end

    private

    # Checks all the running tests.
    def check_running_tests
      now = DateTime.now

      run_result = @results_database.get_run_result
      test_results = @test_database.get_running_test_results(run_result)
      test_results.each do |test_result|
        # If the test hasn't registered itself, we don't process it.
        test_name = test_result.test.test_name
        test_info = @tests[test_name]
        next if test_info.nil?
        # A test is 'hung' if its execution time is more twice its usual average.
        # The average execution time for this test.
        average = test_info.average
        average = @default_duration if average == 0
        start_date_time = test_result.start_date_time.to_datetime
        current = (now - start_date_time) * 86400 # days to seconds
        average_str = average.zero? ? '???' : Automation::Converter.seconds_to_duration(average)
        current_str = Automation::Converter.seconds_to_duration(current)
        # Kill if the current execution time is more than the minimum duration AND more than twice the usual average.
        # OR if the current execution time is more than the maximum allowed duration.
        if (current > @minimum_duration && current > average * 2) || (current > @maximum_duration)
          begin
            @logger.info("'#{test_name}' hung - Average: #{average_str}; Current: #{current_str};")
            target = test_result.properties['target']
            _, pid = target.split(':')

            @logger.debug("Killing process #{pid}")
            pid = Integer(pid)
            output, status = popen_capture('taskkill', '/F', '/PID', pid.to_s)
            if status.exitstatus == 0
              @logger.warn("Process (PID:#{pid}) was killed.")
              @test_database.with_transaction do
                test_result.lock!
                test_result.result = Automation::Result::TimedOut
                test_result.status = Status::Complete
                test_result.end_date_time = DateTime.now
                test_result.save
              end
            else
              @logger.warn("Taskkill failed - '#{test_name}' (#{target})\n#{output}")
            end
          rescue
            @logger.warn("Cannot kill '#{test_name}' (#{target})")
            @logger.debug(format_exception($!))
          ensure
            @tests.delete(test_name)
            @logger.debug("Un-registered '#{test_name}'")
          end
        end

        # A test sends a 'heartbeat' at regular intervals. TODO: If no heartbeat is received for some time,
        # we do something!
        time_since = (now - test_info.last_update) * 86400 # days to seconds
        time_since_str = Automation::Converter.seconds_to_duration(time_since)
        if time_since > @heartbeat_timeout
          @logger.info("'#{test_name}' might be hung - Last message received #{time_since_str} ago.")
        end
      end
    end

  end

end
