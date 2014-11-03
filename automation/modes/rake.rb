#
# Suraj Vijayakumar
# 28 Jul 2013
#

require 'rake'

require 'automation/modes/runner'
require 'automation/modes/single'

module Automation

  # Executes tests using Rake.
  class Rake < Runner

    private

    # Overridden to create Rake tasks.
    def process_task(task, group, overrides = {})
      create_task(task, group, overrides)
    end

    # Overridden to create an empty Rake task (so that tasks can depend on it).
    def process_task_group(group)
      create_rake_task(group, get_tasks(group) + get_group_depends_on(group))
    end

    # The following steps are carried out (in no particular order):
    # 1. Launch rake.
    def run
      super

      ::Rake.application[@runner_target.to_sym].invoke
    end

    # Creates a rake task with the specified details.
    #
    # @param [String] task the task's name.
    # @param [Array] prerequisites the task's prerequisites.
    # @param [Proc] block the work the task needs to do.
    def create_rake_task(task, prerequisites, &block)
      task = task.to_sym
      prerequisites = prerequisites.map { |p| p.to_sym }
      # Create the task and add it to the list of pre-requisites of its group.
      ::Rake::Task.define_task(task => prerequisites, &block)
    end

    # Creates a task that will execute the specified framework task.
    #
    # @param [String] task the task to create.
    # @param [String] group the group the task belongs to.
    # @param [Hash] overrides optional overrides
    #   :task_name - the name of the rake task - defaults to the task name.
    #   :args - optional command line arguments to pass to the framework.
    #   :depends_on - additional pre-requisites.
    def create_task(task, group, overrides = {})
      defaults = {task_name: task, args: [], depends_on: []}
      overrides = defaults.merge(overrides)
      #
      task_name = overrides[:task_name]
      args = overrides[:args]
      depends_on = overrides[:depends_on]
      # A task depends on everything it depends on and everything the task's group depends on.
      depends_on = (depends_on + get_depends_on(group, task))

      # Create an empty rake task if the task has been marked as disabled.
      unless task_enabled?(task)
        create_rake_task(task_name, depends_on)
        return
      end

      # Create a rake task that will launch the required framework task.
      create_rake_task(task_name, depends_on) do
        @logger.info("Launching task '#{task_name}'...")
        affinity = -1 # No processor affinity - since Rake runs only one task at a time.
        exitstatus = Single.launch_process(task, affinity, *(@cl_propagate + args))
        if stop_on_failure?(group, task) && (exitstatus > 0)
          raise ExecutionError.new("Task '#{task_name}' failed - exit code: #{exitstatus}")
        end
      end
    end

  end

end
