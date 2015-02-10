#
# Suraj Vijayakumar
# 09 May 2013
#

require 'automation/core/result_data'

module Automation

# Represents the result data of a run.
  class RunResultData < ZipResultData

    # New run result data object.
    #
    # @param [String] directory the root directory.
    # @param [String] run_name the name of the run.
    # @param [Boolean] create if true, the zip file is created.
    def initialize(directory, run_name, create = true)
      config_manager = runtime.config_manager
      zip_file_name = config_manager['run.result.zip_file_name', parameters: {'run.name' => run_name}]
      zip_path = File.join(directory, zip_file_name)

      super(zip_path, create)
    end

  end

end
