#
# Suraj Vijayakumar
# 18 Dec 2013
#

require 'automation/core/result_data'

module Automation

# Represents the result data of a task.
  class TaskResultData < ZipResultData

    # New task result data object.
    #
    # @param [String] directory the root directory.
    # @param [String] task_name the name of the task.
    # @param [Boolean] create if true, the zip file is created.
    def initialize(directory, task_name, create = true)
      config_manager = runtime.config_manager
      zip_file_name = config_manager['task.results.zip_file_name', parameters: {'task.name' => task_name}]
      zip_path = File.join(directory, zip_file_name)

      super(zip_path, create)
    end

  end

end
