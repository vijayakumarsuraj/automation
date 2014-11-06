#
# Suraj Vijayakumar
# 06 Aug 2013
#

require 'automation/modes/runner'

module Automation

  # Executes tests using IncrediBuild.
  class Incredibuild < Runner

    def initialize
      super

      @tasks_xml = {}
    end

    private

    # Overridden to create Task tags.
    def process_task(task, group, overrides = {})
      @tasks_xml[group] << create_task(task, group, overrides)
    end

    # Overridden to do nothing (much).
    def process_task_group(group)
      @tasks_xml[group] = []
    end

    # The following steps are carried out (in no particular order):
    # 1. Launch IncrediBuild.
    def run
      super

      task_groups_xml = []
      @tasks_xml.each_pair { |group, tasks| task_groups_xml << create_task_group(group, tasks) }

      # Generate the build XML.
      @logger.debug('Generating IncrediBuild build file...')
      params = {':ruby_bin' => environment.ruby_bin, ':args' => Converter.to_command_line_args(@cl_propagate),
                ':task_groups' => task_groups_xml.join("\n")}
      xml = @config_manager['incredibuild.script.xml', parameters: params]
      # Write to the build file.
      @build_file = File.join(@config_manager['run.working.directory'], 'incredibuild.xml')
      File.write(@build_file, xml)

      @logger.debug('Launching IncrediBuild...')
      ib_executable = @config_manager['tool.incredibuild.executable']
      options = @config_manager['tool.incredibuild.options']
      # Launch IncrediBuild.
      args = [@build_file] + options
      popen(ib_executable, *args) { |line| puts line }
      # Update run result.
      run_result = @results_database.get_run_result
      if run_result.status != Automation::Status::Complete
        run_result.status = Automation::Status::Complete
        run_result.result = Automation::Result::Unknown
        run_result.end_date_time = DateTime.now
        run_result.save
      end
      # Update this mode's result to match that of the run.
      update_result(run_result.result)
    end

    # Creates the task group xml.
    #
    # @param [String] group the task group.
    # @param [Array] tasks the task XMLs.
    # @return [String] the task group xml.
    def create_task_group(group, tasks)
      xml = ''

      params = {':task_group' => group, ':stop_on_failure' => group_stop_on_failure?(group),
                ':depends_on' => get_group_depends_on(group).join(',')}
      xml << ' ' * 4 + @config_manager['incredibuild.script.task_group.begin', parameters: params] + "\n"
      tasks.each { |task_xml| xml << ' ' * 6 + task_xml + "\n" }
      xml << ' ' * 4 + @config_manager['incredibuild.script.task_group.end']
      # Return full xml.
      xml
    end

    # Creates the target for the specified task.
    #
    # @param [String] task the task.
    # @param [String] group the task's group.
    # @return [String] the target string.
    def create_task(task, group, overrides = {})
      defaults = {task_name: task, args: [], depends_on: []}
      overrides = defaults.merge(overrides)
      # Dependencies - task + overrides
      config_key = 'incredibuild.script.local_task'
      config_key = 'incredibuild.script.empty_task' unless task_enabled?(task)
      depends_on = (overrides[:depends_on] + get_task_depends_on(task)).join(',')

      # The target string.
      params = {':source_file' => task, ':task_name' => overrides[:task_name],
                ':depends_on' => depends_on, ':params' => overrides[:args].join(' '),
                ':stop_on_failure' => task_stop_on_failure?(task)}
      @config_manager[config_key, parameters: params]
    end

  end

end
