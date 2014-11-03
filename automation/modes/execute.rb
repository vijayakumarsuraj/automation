#
# Suraj Vijayakumar
# 10 Aug 2013
#

require 'executor/task_list'

require 'automation/modes/runner'
require 'automation/modes/single'

module Automation

  # Executes tests using the executor library.
  class Execute < Runner

    def initialize
      super

      # Initialises the variables needed to calculate processor affinity values.
      @processor_ids = Queue.new
      @number_of_processors = Automation.environment.number_of_processors
      @number_of_processors.times { |i| @processor_ids.push(i) }

      @executor_threads = Concurrent::ThreadPool.new(@number_of_processors, 'Automation::Executor::ThreadPool', 'executor-thread')
      @task_list = Executor::TaskList.new
    end

    # Overridden to create Executor tasks.
    def process_task(task, group, overrides = {})
      create_task(task, group, overrides)
    end

    # Overridden to create an empty Executor task (so that actual tasks can depend on it).
    def process_task_group(group)
      create_executor_task(group, get_tasks(group) + get_group_depends_on(group)) {}
    end

    # The following steps are carried out (in no particular order):
    # 1. Run the task list.
    def run
      super

      Executor.execute(@task_list, @executor_threads)
    end

    private

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
      depends_on = depends_on + get_depends_on(group, task)

      # Create an empty task if the task has been marked as disabled.
      unless task_enabled?(task)
        create_executor_task(task_name, depends_on) {}
        return
      end

      # Create a task that will launch the required framework task.
      create_executor_task(task_name, depends_on) do
        begin
          # Get the next available processor id. Will throw an exception if there are no available processors.
          id = @processor_ids.pop(true)
          @logger.info("Launching task '#{task_name}' (affinity=#{id})...")
          @logger.fine((@cl_propagate + args).inspect)
          exitstatus = Single.launch_process(task, id, *(@cl_propagate + args))
          if stop_on_failure?(group, task) && (exitstatus > 0)
            Executor.raise_error(@task_list, ExecutionError.new("Task '#{task_name}' failed - exit code: #{exitstatus}"))
          end
        ensure
          # Always push the processor id back. So that another task can re-use it.
          @processor_ids.push(id) if (defined? id) && !id.nil?
        end
      end
    end

    # Defines an executor task.
    #
    # @param [String] id the id for the task.
    # @param [Array] depends_on an array of dependent task ids.
    # @param [Proc] block the work this task will perform.
    def create_executor_task(id, depends_on, &block)
      @task_list.define(id, *depends_on, &block)
    end

  end

end
