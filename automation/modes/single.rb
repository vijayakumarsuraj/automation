#
# Suraj Vijayakumar
# 01 Mar 2013
#

require 'automation/core/mode'

module Automation

  # Special node for executing any single task.
  class Single < Mode

    module CommandLineOptions

      private

      # Method for creating the task option.
      def option_task
        block = proc { |id| @task_id = id }
        @cl_parser.on('--task ID', 'Specify the name of the task to execute.', &block)
      end

    end

    include Automation::Single::CommandLineOptions

    # Launches a new framework process for the specified task.
    #
    # @param [String] task the task id to execute.
    # @param [Fixnum] affinity the processor affinity for the launched process. -1 to specify no affinity.
    # @param [Array] args optional command line arguments.
    # @return [Integer] the return code of the specified task.
    def self.launch_process(task, affinity, *args)
      application = Automation.environment.config_manager['run.application']
      ruby_bin = Automation.environment.ruby_bin
      ruby = Automation::Converter.to_windows_path(File.join(ruby_bin, 'ruby'))
      main_rb = File.join(Automation::FRAMEWORK_ROOT, 'main.rb')
      args = [main_rb, "#{application}-single", '--task', task] + args
      if affinity >= 0
        # An affinity was specified, launch the process using the 'start' command and the /affinity option.
        # The affinity also needs to be converted into a hexadecimal mask.
        affinity_mask = (2 ** affinity).to_s(16)
        args = ['/b', '/affinity', affinity_mask, ruby] + args
        return popen('start', *args) { |line| puts line }.exitstatus
      else
        return popen(ruby, *args) { |line| puts line }.exitstatus
      end
    end

    # New single mode.
    def initialize
      super

      @task_id = nil
    end

    private

    # The following steps are carried out (in no particular order):
    # 1. Pop task id from the logging NDC.
    def cleanup
      Logging.ndc.pop
      super
    end

    # Adds the options that the Single mode supports.
    def create_mode_options
      super
      #
      option_task
    end

    # Overridden to return the name of the test when the task is 'test_runner'. Otherwise use the default behaviour.
    def log_file_name
      @task_id == 'test_runner' ? "#{@test_name}" : @task_id
    end

    # The following steps are carried out (in no particular order):
    # 1. Validate command line options.
    # 2. Load and execute the required task.
    def run
      super
      #
      @logger.info('Running...')
      raise CommandLineError.new('Cannot execute - SingleMode expects a task id') if @task_id.nil?
      # Load the task and execute it!.
      task = load_component(Automation::Component::TaskType, @task_id)
      task.start
      # Update the result of the mode to match the task it executed.
      update_result(task.result)
    end

    # The following steps are carried out (in no particular order):
    # 1. Push task id into the logging NDC.
    def setup
      super
      Logging.ndc.push(@task_id)
    end

  end

end