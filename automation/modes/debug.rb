#
# Suraj Vijayakumar
# 08 Jan 2013
#

require 'automation/modes/runner'

module Automation

  # Standard mode for development and debug activities. Runs all tasks in a single process.
  # Restricts the number of tests that can be executed to 1.
  #
  # Dependencies are not honoured. Groups are run in the order they were defined.
  # i.e. setup -> tests -> teardown (by default)
  #
  # Within groups, tasks are also executed in the order they were defined.
  class Debug < Runner

    # New debug mode.
    def initialize
      super

      @archive_results = true
      @tasks = []
    end

    private

    # Overridden to use the name of the test being executed.
    def log_file_name
      @test_name == '*' ? super : @test_name
    end

    # Overridden to store the name of the task.
    def process_task(task, group, overrides = {})
      @tasks << [task, group]
    end

    # Overridden to do nothing.
    def process_task_group(group)
      # Don't need to do anything.
    end

    # The following steps are carried out (in no particular order):
    # 1. Validate non option command line arguments.
    # 2. Start required tasks.
    def run
      raise CommandLineError.new('Cannot execute - DebugMode expects exactly one test') if @selected_test_names.length != '1'
      #
      super
      # Execute each task now.
      @logger.info('Running...')
      @tasks.each do |task, group|
        next unless task_enabled?(task)

        begin
          load_component(Automation::Component::TaskType, task).start
        rescue
          # If the stop_on_failure flag evaluates to true, raise this exception.
          group_stop_on_failure = @config_manager["task_groups.#{group}.stop_on_failure", default: []]
          task_stop_on_failure = @config_manager["task.#{task}.stop_on_failure", default: []]
          raise if (group_stop_on_failure || task_stop_on_failure)
          # Else, just log an error message and move on.
          @logger.error(format_exception)
        end
      end
    end

  end

end
