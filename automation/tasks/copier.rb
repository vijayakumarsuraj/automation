#
# Suraj Vijayakumar
# 03 Jan 2013
#

require 'automation/core/task'
require 'automation/support/file_system_methods'

module Automation

  # The base class for tasks that copy data.
  class Copier < Task

    # Provides convenience methods for working with the underlying file system.
    include Automation::FileSystemMethods

    # New copier.
    def initialize
      super

      @persist = task_config('persist', default: @persist)
    end

    private

    # The following steps are carried out by the default copier (in no particular order):
    # 1. Notify any listeners that this copier has finished.
    def cleanup
      notify_change('copier_finished', @component_name)

      super
    end

    # The following steps are carried out by the default copier (in no particular order):
    # 1. Notify any listeners that this copier has failed.
    def exception(ex)
      notify_change('copier_failed', @component_name)

      super
    end

    # The following steps are carried out by the default copier (in no particular order):
    # 1. Copies files from the source to the destination.
    def run
      source = copier_config('source')
      destination = copier_config('destination')
      patterns = copier_config('patterns', default: %w(*))
      clean = copier_config('clean', default: false)
      # Copy the required files.
      copy(source, destination, patterns: patterns, clean: clean)
    end

    # The following steps are carried out by the default copier (in no particular order):
    # 1. Notify any listeners that this copier has started.
    def setup
      super

      notify_change('copier_started', @component_name)
    end

    # Copies files from the source to the destination.
    #
    # @param [String] source the source directory.
    # @param [String] destination the destination directory.
    # @param [Hash] overrides optional overrides
    #   clean: if true, deletes the contents of the destination folder before copying (default is false).
    #   patterns: only files and folders that match this pattern are copied (default is *).
    def copy(source, destination, overrides = {})
      if File.directory?(source)
        @logger.info("Copying '#{source}' to '#{destination}'...")
        @logger.fine(overrides.inspect)
        dir_copy(source, destination, overrides)
      else
        raise NotImplementedError.new("Source '#{source}' is not a directory")
      end
    end

    # Get a copier specific config entry value.
    #
    # @param [String] key
    # @param [Hash] options
    # @return [String]
    def copier_config(key, options = {})
      task_config("copy.#{key}", options)
    end

  end

end
