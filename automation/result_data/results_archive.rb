#
# Suraj Vijayakumar
# 20 May 2013
#

require 'automation/core/result_data'

require 'automation/support/seven_zip_methods'

module Automation

  # Represents the (remote) results archive.
  class ResultsArchive < ResultData

    include Automation::SevenZipMethods

    # New results archive.
    def initialize
      super

      @root = @config_manager['results.archive']
    end

    # Deletes the run result data for the specified run.
    # Will raise an exception if the required file does not exist.
    #
    # @param [String] run_name
    def delete_run_result(run_name)
      run_result_data = get_run_result(run_name)
      run_result_data.close
      FileUtils.rm(run_result_data.zip_path)
    end

    # Gets the result data for the specified run name from the results archive.
    # Will raise an exception if the required file does not exist.
    #
    # @param [String] run_name the run whose data is required.
    # @return [RunResultData] the run result data object.
    def get_run_result(run_name)
      RunResultData.new(@root, run_name, false)
    end

    # Saves the result data of the specified run to the results archive.
    #
    # @param [String] run_name the name of the run to store.
    def save_run_result(run_name)
      raise IOError.new("Cannot archive - Archive directory '#{@root}' does not exist") unless File.directory?(@root)

      run_result_directory = @config_manager['run.result.directory', parameters: {'run.name' => run_name}]
      zip_file_name = @config_manager['run.result.zip_file_name', parameters: {'run.name' => run_name}]

      FileUtils.cd(run_result_directory) do
        # Execute 7z.
        @logger.debug("Archiving run result (#{run_name})...")
        seven_zip_archive(zip_file_name, '*')
        # Copy to the archive.
        @logger.debug("Publishing results (#{run_name})...")
        FileUtils.cp(zip_file_name, @root)
      end
    end

  end

end
