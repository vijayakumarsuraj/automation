#
# Suraj Vijayakumar
# 09 Mar 2013
#

require 'executor/task_observer'

module Executor

  # Represents the dependency between two tasks.
  class Dependency

    # Provides support for listening to task events
    include Executor::TaskObserver

    # Creates a new dependency between the specified tasks.
    #
    # @param [Executor::Task] dependent the dependent task (i.e. the owner of this dependency).
    # @param [Object] prerequisite the prerequisite task id (i.e. the task that the owner depends on).
    def initialize(dependent, prerequisite)
      @dependent = dependent
      @prerequisite_id = prerequisite

      @prerequisite = nil
    end

    # Prepares this dependency by resolving the pre-requisite task name into a task object.
    def resolve_prerequisite
      @prerequisite = @dependent.engine.resolve(@prerequisite_id)
      @prerequisite.add_observer(self, :task_changed)
    end

    # Check if the prerequisite task of this dependency has completed.
    #
    # @return [Boolean] true if the prerequisite task is complete, false otherwise.
    def satisfied?
      @prerequisite.complete?
    end

    private

    # The prerequisite task has completed. So notify the task.
    #
    # @param [Executor::Task] prerequisite the task that completed.
    def on_task_complete(prerequisite)
      @dependent.dependency_satisfied(self)
    end

  end

end