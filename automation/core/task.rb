#
# Suraj Vijayakumar
# 04 Dec 2012
#

require 'automation/core/component'

require 'automation/enums/change'
require 'automation/enums/result'
require 'automation/enums/status'

require 'automation/support/runnable'

module Automation

  # A task represents the most basic unit of work the framework can carry out.
  class Task < Component

    # Makes this task a runnable.
    include Automation::Runnable

    # If true, this task will persist its results to the results database.
    attr_accessor :persist

    # New task.
    def initialize
      super

      @result = Automation::Result::Pass
      @component_name = @component_name.snakecase
      @component_type = Automation::Component::TaskType
      @raise_exceptions = true
      @persist = true

      @databases = environment.databases
      @results_database = @databases.results_database
    end

    # Get the process ID of this task.
    #
    # @return [String, Integer] the PID.
    def pid
      @config_manager['task.pid']
    end

    # Updates the process ID of this task.
    #
    # @param [String, Integer] pid the PID.
    def update_pid(pid)
      @config_manager.add_override_property('task.pid', pid, overwrite: true)
    end

    private

    # Executed after the shutdown method, even if there are exceptions.
    def cleanup
      if defined? @task_result
        @task_result.result = @result
        @task_result.status = Status::Complete
        @task_result.end_date_time = DateTime.now
        @task_result.save
      end
    end

    # Executed if there are exceptions.
    # By default, logs the error and re-raises it.
    #
    # @param [Exception] ex the exception.
    def exception(ex)
      update_result(Automation::Result::Exception)
      raise if @raise_exceptions

      @logger.error(format_exception(ex))
    end

    # Executed before the task runs.
    # By default, all configured observers are loaded.
    def setup
      # Persist this task's results only if the persist flag is set.
      if @persist
        @run_result = @results_database.get_run_result
        @run_config = @run_result.run_config
        @task_entity = @results_database.get_task!(@run_config, @component_name)
        @task_result = @results_database.create_task_result(@run_result, @task_entity)
      end

      load_observers('task', [])
    end

    # Executed after the task runs (if there were no exceptions).
    def shutdown
    end

    # Get a task specific config entry value.
    #
    # @param [String] key
    # @param [Hash] options
    # @return [String]
    def task_config(key, options = {})
      @config_manager["task.#{@component_name}.#{key}", options]
    end

  end

end
