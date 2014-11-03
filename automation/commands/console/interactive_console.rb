#
# Suraj Vijayakumar
# 03 Aug 2013
#

require 'automation/console/console_command'

module Automation

  class InteractiveConsoleCommand < ConsoleCommand

    # Empty class that will be binding context for all statements executed here.
    class InteractiveConsole
    end

    # New interactive console command.
    #
    # @param [Automation::Console] console the mode that executed this command.
    def initialize(console)
      super
    end

    # Executes the interactive console.
    def execute
      __binding__ = binding
      while true
        command = prompt('IC> ')
        return if command.eql?('exit')

        begin
          result = eval(command, __binding__)
          echo(result) unless result.nil?
        rescue
          echo(format_exception($!))
        end
      end
    end

  end

end
