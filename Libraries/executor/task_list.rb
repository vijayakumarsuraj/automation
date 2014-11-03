#
# Suraj Vijayakumar
# 09 Mar 2013
#

require 'thread'

require 'executor/error'
require 'executor/task'
require 'executor/task_observer'

module Executor

  # Executes the specified task list on the specified thread pool.
  #
  # @param [TaskList] task_list the list of tasks to execute.
  # @param [Concurrent::ThreadPool] thread_pool the thread pool that will execute these tasks.
  # @param [Boolean] wait if true, wait for all the tasks to complete before returning.
  def self.execute(task_list, thread_pool, wait = true)
    task_list.execute(thread_pool, wait)
  end

  # Stops the specified task list.
  #
  # @param [TaskList] task_list the task list to stop.
  # @param [StandardError] error the reason for stopping the task list.
  def self.raise_error(task_list, error = $!)
    task_list.raise_error(error)
  end

  # Represents a collection of related tasks.
  class TaskList

    # Provides support for listening to task events
    include Executor::TaskObserver

    # Creates a new task list.
    def initialize
      @tasks = {}

      @compiled = false
      @stopped = false
    end

    # Define and add a task to this task list.
    def define(id, *depends_on, &block)
      raise TaskListError.new('Cannot define - list stopped') if @stopped
      raise TaskListError.new('Cannot define - list already started') if @compiled
      raise TaskListError.new("Cannot define - task '#{id}' already exists") if @tasks.has_key?(id)
      # Create and schedule the task.
      task = Task.new(id, &block)
      task.depends_on(*depends_on)
      task.add_observer(self, :task_changed)
      task.scheduled(self)
      @tasks[id] = task
    end

    # Compiles this task list (resolves dependencies) and begins execution.
    # Waits for the execution to complete before returning.
    #
    # @param [Concurrent::ThreadPool, Queue] thread_pool the thread pool that will execute these tasks.
    # @param [Boolean] wait if true, wait for all the tasks to complete before returning.
    def execute(thread_pool, wait = true)
      raise TaskListError.new('Cannot execute - list stopped') if @stopped
      raise TaskListError.new('Cannot execute - already started') if @compiled

      @compiled = true
      @thread_pool = thread_pool

      @tasks.each_value { |task| task.resolve_dependencies }
      @tasks.each_value { |task| @thread_pool.submit(task) if task.ready? }

      wait_for if wait
    end

    # Resolves the provided task id to a task object.
    #
    # @param [String] id the task id to resolve.
    # @return [Executor::Task] the task object.
    def resolve(id)
      raise TaskListError.new("Cannot resolve - task '#{id}' does not exist") unless @tasks.has_key?(id)
      # Get the required task.
      @tasks[id]
    end

    # Raises an error and stops all un-executed tasks.
    #
    # @param [StandardError] error the error.
    def raise_error(error = $!)
      raise TaskListError.new('Cannot stop - not started') unless @compiled

      @stopped = true
      @tasks.each_value { |task| task.raise_error(error) }
    end

    # Waits for all queued tasks to complete.
    def wait_for
      raise TaskListError.new('Cannot wait - not started') unless @compiled

      @tasks.each_value { |task| task.result }
    end

    private

    # Queues the task on the list's thread pool.
    def on_task_ready(task)
      return if @stopped

      @thread_pool.submit(task)
    end

  end

end