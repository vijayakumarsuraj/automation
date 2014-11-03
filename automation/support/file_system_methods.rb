#
# Suraj Vijayakumar
# 05 Jul 2013
#

module Automation

  # Provides methods for copying files and directories.
  module FileSystemMethods

    private

    # Copies files from the the specified source folder to the specified destination folder.
    # The destination folder is created (including any parent folders) if it does not exist.
    #
    # @param [String] source the source directory.
    # @param [String] destination the destination directory.
    # @param [Hash] overrides optional overrides
    #   clean: if true, deletes the contents of the destination folder before copying (default is false).
    #   patterns: only files and folders that match this pattern are copied (default is *).
    def dir_copy(source, destination, overrides = {})
      defaults = {clean: false, patterns: %w(*)}
      overrides = defaults.merge(overrides)
      # Clean the destination directory (creating it if required).
      FileUtils.rm_r(destination) if overrides[:clean] && File.exist?(destination)
      FileUtils.mkdir_p(destination)
      # Copy all files from the source directory to the destination directory.
      FileUtils.cd(source) do
        files = []
        patterns = overrides[:patterns]
        patterns.each { |pattern| files += Dir.glob(pattern) }
        files_copy(files.uniq, destination)
      end
    end

    # Copies the specified list of files to the specified destination folder.
    # The destination folder is created (including any parent folders) if it does not exist.
    #
    # @param [Array<String>] files the list of files to copy.
    # @param [String] destination the destination directory.
    # @param [Hash] overrides optional overrides
    #   ignore_missing: if true, missing files will not throw an error (default is false).
    def files_copy(files, destination, overrides = {})
      defaults = {ignore_missing: false}
      overrides = defaults.merge(overrides)
      @logger.debug("Copying #{files.length} items from '#{Dir.pwd}' to '#{destination}'")
      background(files, WAIT_FOR_RESULT) do |file|
        if File.exist?(file) || !overrides[:ignore_missing]
          @logger.fine { "Copying '#{file}'..." }
          FileUtils.cp_r(file, destination)
        else
          @logger.fine("Skipped '#{file}' - does not exist")
        end
      end
    end

  end

end
