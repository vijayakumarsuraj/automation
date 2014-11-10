#
# Suraj Vijayakumar
# 11 Nov 2014
#

require 'automation/bootstrap/kernel'

module Automation

  module AllureReport

    extend Automation::Kernel

    # Generates a report off of the results in the specified directory.
    # The report is also generated into this directory.
    #
    # @param [String] output_directory
    def self.generate(output_directory)
      config_manager = environment.config_manager
      allure_bat = config_manager['tool.allure.executable']
      args = ['generate', '-o', output_directory, output_directory]
      output, status = popen_capture(allure_bat, *args)
      raise ExecutionError.new('Allure encountered errors.') if status.exitstatus != 0
    end

  end

end