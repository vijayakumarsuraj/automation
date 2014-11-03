#
# Suraj Vijayakumar
# 25 May 2013
#

require 'automation/core/command'

module Automation

  class ConsoleCommand < Command

    private

    # Reads a message from the console.
    #
    # @param [String] prompt Optional prompt message.
    # @return [String] the message read from the console.
    def prompt(prompt = '')
      @parent.prompt(prompt)
    end

    # Writes a message to the console.
    #
    # @param [String] message the message.
    def echo(message)
      @parent.echo(message)
    end

  end

end