#
# Suraj Vijayakumar
# 09 Mar 2013
#

require 'observer'

require 'concurrent/task'

require 'executor/dependency'
require 'executor/error'
require 'executor/task_observer'

module Executor

  # Extension of the concurrent task class to add support for inter-task dependencies.
  class Task < Concurrent::Task

    # Include support for notifying observers of changes to the task.
    include Observable

    # The identifier for this task.
    #
    # @return [String]
    attr_reader :id

    # The executor engine where this task has been scheduled.
    #
    # @return [Executor::Engine]
    attr_reader :engine

    # Creates a new task.
    #
    # @param [String] id an identifier for this task.
    # @param [Proc] block a proc that represents the work of this task.
    def initialize(id, &block)
      super(&block)

      @id = id

      @dependencies = []
      @dependency_counter = 0
      @engine = nil
    end

    # Executes this task.
    def execute
      super
    ensure
      changed
      notify_observers(self, 'complete')
    end

    # Notify this task that one of its dependencies have been satisfied.
    #
    # @param [Executor::Dependency] dependency
    def dependency_satisfied(dependency)
      @mutex.synchronize do
        @dependency_counter += 1
        return if @dependency_counter != @dependencies.length
      end
      # If all dependencies have been satisfied, notify observers (only happens once).
      changed
      notify_observers(self, 'ready')
    end

    # Adds a dependency for this task.
    #
    # @param [Array<String>] task_ids the list of task names this task depends on.
    def depends_on(*task_ids)
      task_ids.each { |id| @dependencies << Dependency.new(self, id) }
    end

    # Check if this task is ready to be executed (i.e. all dependencies have been satisfied).
    #
    # @return [Boolean] true if ready, false otherwise.
    def ready?
      @dependency_counter >= @dependencies.length
    end

    # Prepares this task for execution by resolving all dependencies.
    def resolve_dependencies
      @dependencies.each { |d| d.resolve_prerequisite }
    end

    # Indicates that this task has been scheduled (queued) for execution.
    #
    # @param [Executor::TaskList] engine the engine where it has been scheduled.
    def scheduled(engine)
      @engine = engine
    end

  end

end