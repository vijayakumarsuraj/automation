#
# Suraj Vijayakumar
# 18 Feb 2014
#

require 'securerandom'

require 'automation/console/console_command'

module Automation

  class PasswordCommand < ConsoleCommand

    # Password command.
    #
    # @param [Automation::Console] console the mode that executed this command.
    def initialize(console)
      super
    end

    # Executes the password command.
    def execute
      string = prompt('String: ')

      echo('Encrypting...')
      salt = SecureRandom.base64(6)
      password = Digest::SHA2.hexdigest(salt + string)

      echo('')
      echo("Password: #{password}")
      echo("Salt    : #{salt}")
    end

  end

end
