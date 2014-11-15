#
# Suraj Vijayakumar
# 19 Jun 2013
#

require 'automation/modes/runner'

module Automation

  # Executes tests using Ant.
  class Ant < Runner

    module CommandLineOptions

      # Method for creating the ant options.
      def option_ant
        block = proc { |ant_home| save_option_value('tool.ant.home', ant_home) }
        @cl_parser.on('--ant-home PATH', 'Specify the path where Ant is installed.',
                      'If skipped, the environment variable ANT_HOME is used.', &block)
      end

    end

    # Include the Ant specific command line options.
    include Automation::Ant::CommandLineOptions

    def initialize
      super

      @extension_points_xml = []
      @targets_xml = []
    end

    private

    def create_mode_options
      super

      option_ant
    end

    # Overridden to create target tags.
    def process_task(task, group, overrides = {})
      @targets_xml << create_target(task, group, overrides)
    end

    # Overridden to create extension point tags.
    def process_task_group(group)
      @extension_points_xml << create_extension_point(group)
    end

    # The following steps are carried out (in no particular order):
    # 1. Launch Ant.
    def run
      super

      # Generate the build XML.
      @logger.debug('Generating Ant build file...')
      params = {':ruby_bin' => environment.ruby_bin, ':args' => Converter.to_command_line_args(@cl_propagate),
                ':targets' => @targets_xml.join("\n"), ':extension_points' => @extension_points_xml.join("\n")}
      xml = @config_manager['ant.script.xml', parameters: params]
      # Write to the build file.
      @build_file = File.join(@config_manager['run.working.directory'], 'ant.xml')
      File.write(@build_file, xml)

      @logger.debug('Launching Ant...')
      ant_home = @config_manager['tool.ant.home']
      ant_executable = File.join(ant_home, 'bin', @config_manager['tool.ant.executable'])
      options = @config_manager['tool.ant.options']
      # Command line arguments.
      ant_args = ['-buildfile', @build_file] + options
      # Parallel Ant specific arguments.
      pant_args = ['-lib', @config_manager['ant.pant.lib'],
                   '-logger', @config_manager['ant.pant.logger'],
                   "-Dant.executor.class=#{@config_manager['ant.pant.executor']}",
                   "-Dpant.threads=#{environment.number_of_processors}"]
      # Launch Ant.
      args = ant_args + pant_args + [@runner_target]
      process_status = popen(ant_executable, *args) { |line| puts line }
      # Update result to the Ant return code.
      update_result(Automation::Result::ByReturnValue[process_status.exitstatus])
    end

    # Creates an extension point for the specified task group.
    #
    # @param [String] group the task group.
    # @return [String] the extension point string.
    def create_extension_point(group)
      params = {':task_group' => group, ':depends_on' => get_group_depends_on(group).join(',')}
      '  ' + @config_manager['ant.script.extension_point', parameters: params]
    end

    # Creates the target for the specified task.
    #
    # @param [String] task the task.
    # @param [String] group the task's group.
    # @return [String] the target string.
    def create_target(task, group, overrides = {})
      defaults = {target_name: task, args: '', depends_on: []}
      overrides = defaults.merge(overrides)
      #
      target_name = overrides[:task_name]
      args = overrides[:args].join(' ')
      depends_on = overrides[:depends_on]
      # A target depends on everything its task depends on and everything the task's group depends on.
      config_key = task_enabled?(task) ? 'ant.script.target' : 'ant.script.empty_target'
      depends_on = (depends_on + get_depends_on(group, task)).join(',')

      # The target string.
      params = {':target_name' => target_name, ':task_name' => task,
                ':depends_on' => depends_on, ':task_group' => group,
                ':args' => args, ':stop_on_failure' => stop_on_failure?(group, task)}
      '  ' + @config_manager[config_key, parameters: params]
    end

  end

end
