#
# Suraj Vijayakumar
# 25 May 2013
#

require 'automation/modes/support'
require 'automation/console/error'

module Automation

  # Console mode.
  class Console < SupportMode

    # New interactive console mode.
    def initialize
      super

      @title = 'Interactive Console'
    end

    # Reads a message from the console.
    #
    # @param [String] prompt Optional prompt message.
    # @return [String] the message read from the console.
    def prompt(prompt = '')
      prompt.empty? ? $stdout.write('$> ') : $stdout.write("$> #{prompt}")
      $stdin.readline.chomp.strip
    end

    # Writes a message to the console.
    #
    # @param [String] message the message.
    def echo(message)
      $stdout.puts(message)
    end

    private

    def run
      echo_title
      echo_welcome_message

      while true
        begin
          command_name = prompt
          break if command_name.eql?('exit')

          command = load_command(command_name)
          command.execute
        rescue ConsoleError
          echo($!.message)
        end
      end
    end

    # The following steps are carried out (in no particular order):
    def setup
      super

      tasks = @config_manager['task_groups.setup.tasks']
      tasks.each do |task_name|
        next unless task_enabled?(task_name)

        task = load_component(Component::TaskType, task_name)
        task.persist = false
        task.start
      end
    end

    # The following steps are carried out (in no particular order):
    def shutdown
      tasks = @config_manager['task_groups.teardown.tasks']
      tasks.each do |task_name|
        next unless task_enabled?(task_name)

        task = load_component(Component::TaskType, task_name)
        task.persist = false
        task.start
      end

      super
    end

    # Echo the title for this console.
    def echo_title
      echo("----------- #{@title} -----------")
    end

    # Echo a welcome message for this console.
    def echo_welcome_message
      echo('Enter a command to begin')
    end

    # Loads the command with the specified name.
    #
    # @param [String] command the command to load.
    # @return [Automation::ConsoleCommand] the loaded command.
    def load_command(command)
      overrides = {class_name: "#{command.camelcase(:upper)}Command", singleton: true}
      load_component(Component::CommandType, command, self, overrides)
    rescue Exception
      raise ConsoleError.new("Command '#{command}' not loaded!", $!)
    end

    # Get the 'enabled' flag for this task.
    #
    # @param [String] task
    # @return [Boolean] true or false.
    def task_enabled?(task)
      @config_manager["task.#{task}.enabled", default: true]
    end

  end

end
