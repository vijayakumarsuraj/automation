#
# Suraj Vijayakumar
# 08 Mar 2013
#

require 'thread'

require 'concurrent/error'

module Concurrent

  module TaskStatus

    # Check if the task has completed.
    #
    # @return [Boolean] true if the task has completed, false otherwise.
    def complete?
      @mutex.synchronize { @task_complete }
    end

    # Check if the tasks has been queued.
    #
    # @return [Boolean] true if the task is currently queued (but not running), false otherwise.
    def queued?
      @mutex.synchronize { @task_queued }
    end

    # Check if the task is running.
    #
    # @return [Boolean] true if the task is running (but not complete), false otherwise.
    def running?
      @mutex.synchronize { @task_running }
    end

  end

  # Represents a task that can be executed by a thread pool.
  class Task

    include Concurrent::TaskStatus

    # New task.
    #
    # @param [Proc] job the block of work for this task.
    def initialize(*args, &job)
      @args = args
      @job = job

      @mutex = Mutex.new
      @token = ConditionVariable.new

      @task_queued = false
      @task_running = false
      @task_complete = false

      @task_result = nil
      @task_error = nil
    end

    # Executes this task.
    def execute
      @mutex.synchronize do
        @task_queued = false
        @task_running = true
      end
      # Call the block that will do the actual work of this task.
      @task_result = @job.call(*@args)
    rescue Concurrent::ThreadPoolShutdownNow
      # Raised by thread pools when they are shutdown. Tasks stop when they see this error.
      set_error(Concurrent::TaskRuntimeError.new('Task interrupted - Thread pool is shutting down', $!))
      # The Thread that is running this task should also stop, so we re-raise it here.
      raise
    rescue
      # Any other exceptions are saved to be raised when the result of this task is queried.
      set_error(Concurrent::TaskRuntimeError.new('Error encountered while executing task', $!))
    ensure
      # All done, we need to wake up all threads that are waiting on this task.
      notify_complete
    end

    # Mark this task as queued. Will throw an error if the task has already been queued.
    def queued
      @mutex.synchronize do
        raise Concurrent::ConcurrencyError.new('Cannot queue - Task is already queued') if @task_queued
        raise Concurrent::ConcurrencyError.new('Cannot queue - Task is already running') if @task_running
        raise Concurrent::ConcurrencyError.new('Cannot queue - Task has already completed') if @task_complete

        @task_queued = true
      end
    end

    # Raises an exception in the thread that is executing this task. Also raises it on all threads that
    # are waiting for this task's result.
    # Any tasks that ask for this task's result will also fail.
    #
    # @param [StandardError] error
    def raise_error(error = $!)
      set_error(error)
      notify_complete
    end

    # Get the result of this task.
    # Waits till the task completes if required.
    #
    # @return [Object] the task's result object.
    def result
      wait_for
      # If the task threw an exception during execution we raise that here.
      @task_error ? raise(@task_error) : @task_result
    end

    # Set the error for this task. The result method will raise this exception.
    def set_error(error)
      @mutex.synchronize { @task_error = error }
    end

    # Instructs the current thread to wait for this task to complete. If the task has already completed, returns
    # immediately.
    def wait_for
      @mutex.synchronize { @token.wait(@mutex) unless @task_complete }
    end

    private

    # Notify all threads that that this task is complete.
    def notify_complete
      @mutex.synchronize do
        @task_running = false
        @task_complete = true
        @token.broadcast
      end
    end

  end

end