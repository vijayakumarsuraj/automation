#
# Suraj Vijayakumar
# 01 Mar 2013
#

require 'automation/core/mode'

module Automation

  # Base class for modes that execute tasks. These modes understand which tasks need to be executed and the order
  # in which they can be executed.
  class Runner < Mode

    module CommandLineOptions

      # Method for creating the trigger options.
      def option_trigger
        block = proc { |name| save_option_value('run.trigger.user', name) }
        @cl_parser.on('--triggered-by NAME', 'Specify the name of the user who triggered this build.',
                      'If skipped, the current user will be used.', &block)
      end

      def option_database
        block = proc { save_option_value('database.results_database.recreate', true) }
        @cl_parser.on('--results-database-recreate', 'Drop the database schema and then re-create it (all data will be lost!).', &block)
      end

    end

    # Include the RunnerMode specific command line options.
    include Automation::Runner::CommandLineOptions

    # New runner mode.
    def initialize
      super

      @tasks = {}
      @archive_results = true
    end

    private

    # Overridden to stop the manager task.
    def cleanup
      if defined? @run_result
        @logger.debug('Saving results...')
        # Run is complete now.
        @run_result.status = Status::Complete
        @run_result.end_date_time = DateTime.now
        @run_result.save
      end

      stop_manager

      super
    end

    # Executes all the tasks selected by this runner.
    def run
      super

      # We inspect the 'triggered by' user to determine if this run should be marked 'official'
      # Official runs are ONLY compared against previous official runs.
      user = @config_manager['run.trigger.user']
      user = ENV['USERNAME'] if user.nil?
      if user.start_with?('[FORCED_OFFICIAL]')
        user = user.sub('[FORCED_OFFICIAL]', '')
        official = true
      else
        user = user.split(';')[0] # A ';' separated list of users, use only the first one.
        official_users = @config_manager['run.trigger.official_users']
        official = official_users.any? { |pattern| user.match(pattern) }
      end

      # Create and save the RunConfig and RunResult entities.
      @run_config = @results_database.get_run_config!
      @run_result = @results_database.create_run_result(@run_config)
      @run_result.mode = @component_name
      @run_result.user = user
      @run_result.official = official
      @run_result.save
      # The run name is passed as an argument to all tasks.
      propagate_option('--run-name', @run_result.run_name)

      # Process the task groups.
      @logger.debug('Generating task list...')
      task_groups = get_task_groups
      @logger.fine("Processing groups (#{task_groups.join(', ')})...")
      task_groups.each { |group| process_task_group(group) }
      task_groups.each { |group| process_tasks(group) }

      # Start the process manager.
      @logger.debug("Starting 'manager'...")
      start_manager

      # The target task that this runner will execute.
      @runner_target = @config_manager['mode.runner.target']

      # Load observers and notify that the run is about to start.
      load_observers('mode', [])
      notify_change('runner_started')
    end

    # Adds the runner specific options.
    def create_mode_options
      option_separator
      option_separator 'Runner options:'
      option_database
      option_trigger
    end

    # Generates the tasks for the specified group.
    #
    # @param [String] group the name of the group.
    def process_tasks(group)
      @logger.finer("Processing tasks for group '#{group}'...")
      method_name = "process_tasks_#{group}"
      tasks = get_tasks(group)
      @logger.finer(tasks.length <= 20 ? "Tasks - #{tasks.join(', ')}" : "Tasks - #{tasks.length} tasks")
      overrides = {args: @cl_non_options}
      respond_to?(method_name, true) ? send(method_name, tasks) : tasks.each { |task| process_task(task, group, overrides) }
    end

    # Starts the manager task.
    def start_manager
      @manager = load_component(Component::TaskType, 'manager')
      @manager.start
    end

    # Stops the manager task.
    def stop_manager
      @manager.stop unless @manager.nil?
    end

    # Get the combined list of dependent groups and tasks.
    #
    # @param [String] group
    # @param [String] task
    # @return [Array<String>] the list of dependent tasks and groups.
    def get_depends_on(group, task)
      group_depends_on = get_group_depends_on(group)
      task_depends_on = get_task_depends_on(task)
      group_depends_on + task_depends_on
    end

    # Get the list of groups this group depends on.
    #
    # @param [String] group
    # @return [Array<String>] the names of the dependent groups
    def get_group_depends_on(group)
      @config_manager["task_groups.#{group}.depends_on", default: []]
    end

    # Get the list of tasks this task depends on.
    #
    # @param [String] task
    # @return [Array<String>] the names of the dependent task
    def get_task_depends_on(task)
      @config_manager["task.#{task}.depends_on", default: []]
    end

    # Returns a list of all task groups (enabled only).
    #
    # @return [Array<String>] the names of all enabled task groups.
    def get_task_groups
      groups = @config_manager['mode.runner.execute']
      groups.select { |group| @config_manager["task_groups.#{group}.enabled", default: true] }
    end

    # Gets the tasks for the specified task group (enabled + disabled)
    #
    # @param [String] group the task group.
    # @return [Array<String>] the names of all the tasks.
    def get_tasks(group)
      method_name = "get_tasks_#{group}"
      respond_to?(method_name, true) ? send(method_name) : @config_manager["task_groups.#{group}.tasks"]
    end

    # Get the 'stop_on_failure' flag for this group.
    #
    # @param [String] group
    # @return [Boolean] true or false.
    def group_stop_on_failure?(group)
      @config_manager["task_groups.#{group}.stop_on_failure", default: false]
    end

    # Check if the stop_on_failure flag is true for the specified group and task.
    #
    # @param [String] group
    # @param [String] task
    # @return [Boolean] true or false.
    def stop_on_failure?(group, task)
      group_stop_on_failure?(group) || task_stop_on_failure?(task)
    end

    # Get the 'enabled' flag for this task.
    #
    # @param [String] task
    # @return [Boolean] true or false.
    def task_enabled?(task)
      @config_manager["task.#{task}.enabled", default: true]
    end

    # Get the 'stop_on_failure' flag for this task.
    #
    # @param [String] task
    # @return [Boolean] true or false.
    def task_stop_on_failure?(task)
      @config_manager["task.#{task}.stop_on_failure", default: false]
    end

    # Processes a task.
    #
    # @param [String] task the name of the task.
    # @param [String] group the group the task belongs to.
    # @param [Hash] overrides optional overrides.
    def process_task(task, group, overrides = {})
      raise NotImplementedError.new("Method 'process_task' not implemented by '#{self.class.name}'")
    end

    # Processes a task group.
    #
    # @param [String] group the name of the group.
    def process_task_group(group)
      raise NotImplementedError.new("Method 'process_task_group' not implemented by '#{self.class.name}'")
    end

  end

end
