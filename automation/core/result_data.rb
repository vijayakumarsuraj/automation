#
# Suraj Vijayakumar
# 25 Mar 2013
#

require 'automation/core/component'

module Automation

  class ResultData < Component

    # Creates a wrapper for result data.
    def initialize
      super

      @component_name = @component_name.snakecase
      @component_type = Automation::Component::ResultDataType
    end

  end

  # Represents a zip file that contains result data.
  class ZipResultData < ResultData

    # The full path to the underlying zip file.
    attr_reader :zip_path

    # New result data object.
    #
    # @param [String] zip_path the full path of the zip file.
    # @param [Boolean] create if true, the zip file is created.
    def initialize(zip_path, create = true)
      super()

      @zip_path = zip_path
      @zip_file = Zip::File.open(@zip_path, create)
    end

    # Adds the specified file to this result data.
    #
    # @param [String] path the source file to add.
    # @param [Hash] overrides optional overrides.
    #   delete_after: if true, the source file is deleted once it is added (default is false).
    #   zipped_name: custom file name when saved to the underlying zip file (default is the source file's name).
    def add(path, overrides = {})
      return unless File.exist?(path)
      #
      defaults = {delete_after: false, zipped_name: File.basename(path)}
      overrides = defaults.merge(overrides)
      # Add the source to the zip archive.
      zipped_name = overrides[:zipped_name]
      delete_after = overrides[:delete_after]
      @zip_file.add(zipped_name, path) { true }
      zip_commit
      # Delete the source if the delete_after flag is true.
      FileUtils.rm_rf(path) if delete_after
    end

    # Closes this result data object. This will close the underlying zip file.
    def close
      zip_commit
      @zip_file.close
    end

    # Check to see if the specified file exists in this result data.
    #
    # @param [String] file_name the name of the file.
    # @return [Boolean] true if the file exists, false otherwise.
    def exist?(file_name)
      @zip_file.file.exist?(file_name)
    end

    # Extracts a file from this result data.
    #
    # @param [String] file_name the file to extract.
    # @param [String] dest the destination location for the file.
    # @param [Hash] overrides optional overrides.
    #   rename: the new name for the file - default is to use the original name of the file.
    def extract(file_name, dest, overrides = {})
      raise Zip::Error.new("File '#{@zip_path}!#{file_name}' does not exist") unless exist?(file_name)
      #
      defaults = {rename: false}
      overrides = defaults.merge(overrides)
      # The destination path.
      rename = overrides[:rename]
      dest_path = rename ? File.join(dest, rename) : File.join(dest, file_name)
      # Extract to the required location.
      FileUtils.rm_f(dest_path) if File.exist?(dest_path)
      @zip_file.extract(file_name, dest_path)
    end

    # Get the contents of the specified file from this result data.
    #
    # @param [String] file_name the name of the file.
    # @return [String] the data.
    def get_data(file_name)
      raise Zip::Error.new("File '#{@zip_path}!#{file_name}' does not exist") unless exist?(file_name)
      @zip_file.read(file_name)
    end

    # Perform some action with the input stream to the specified file.
    #
    # @param [String] file_name the name of the file.
    # @param [Proc] block
    def with(file_name, mode = 'r', &block)
      @zip_file.file.open(file_name, mode, &block)
      zip_commit
    end

    private

    # Commits the changes made to the zip file.
    # If the commit fails, retry up-to the specified number of times. We wait 100ms between tries.
    #
    # @param [Integer] max_retries maximum retries. Default is 5.
    def zip_commit(max_retries = 5)
      attempt_no = 0
      @zip_file.commit
    rescue
      attempt_no += 1
      attempt_no == max_retries ? raise : retry
    end

  end

end
