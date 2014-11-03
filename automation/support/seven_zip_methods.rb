#
# Suraj Vijayakumar
# 31 Oct 2014
#

module Automation

  # Provides the methods for archiving stuff using seven zip.
  module SevenZipMethods

    private

    # Archives the specified files using seven zip.
    #
    # @param [String] zip_file_name
    # @param [Array] files
    def seven_zip_archive(zip_file_name, *files)
      seven_zip_executable = @config_manager['tool.7z.executable']
      output, status = popen_capture(seven_zip_executable, 'a', zip_file_name, *files)
      @logger.fine("7-zip messages\n#{output}")
      raise ExecutionError.new('7-zip encountered errors.') if status.exitstatus != 0
    end

    # Extracts all the files from the specified archive into the current directory.
    #
    # @param [String] zip_file_name
    def seven_zip_extract(zip_file_name, *files)
      seven_zip_executable = @config_manager['tool.7z.executable']
      output, status = popen_capture(seven_zip_executable, 'x', '-y', zip_file_name, *files)
      @logger.fine("7-zip messages\n#{output}")
      raise ExecutionError.new('7-zip encountered errors.') if status.exitstatus != 0
    end

  end

end
