#
# Suraj Vijayakumar
# 01 Nov 2014
#

require 'automation/core/component'

require 'automation/support/file_system_methods'

module Automation

  class PackageError < Automation::Error
  end

  # Represents an abstract package.
  class Package < Automation::Component

    # Provides convenience methods for working with the underlying file system.
    include Automation::FileSystemMethods

    # The name of the package.
    attr_accessor :name

    # Create a new package.
    def initialize
      super

      @base = nil
      @root = Automation::FRAMEWORK_ROOT
      @name = nil
      @items = []

      define
    end

    # Installs this package.
    #
    # @param [String] from
    def install(from)
      uninstall

      @items.each { |items, to, package_dir| copy(File.join(from, package_dir), items, File.expand_path(to, @root)) }
      FileUtils.touch(File.join(@root, 'Gemfile')) # So that the framework sets up it's gems the next time.
    end

    # Creates this package.
    #
    # @param [String] to
    def package(to)
      @items.each { |items, from, package_dir| copy(File.expand_path(from, @root), items, File.join(to, @name, package_dir)) }
    end

    # Uninstalls the package.
    def uninstall
      @items.each { |items, from, _| delete(File.expand_path(from, @root), items) } # Explicitly defined files.
      delete(@base, [@name]) # And the root directory.
      FileUtils.touch(File.join(@root, 'Gemfile')) # So that the framework sets up it's gems the next time.
    end

    private

    # Defines the files contained in this package. Implementations must provide this method.
    def define
      raise NotImplementedError.new("Method 'define' not implemented for '#{self.class.name}'")
    end

    # Define a file for the framework's 'Bin' directory.
    #
    # @param [Array<String>] files
    def bin(package_dir, *files)
      file(package_dir, 'Bin', *files)
    end

    # Copies files.
    #
    # @param [String] from
    # @param [Array<String>] files
    # @param [String] to
    def copy(from, files, to)
      FileUtils.mkdir_p(to)
      FileUtils.cd(from) { files_copy(files, to) }
    end

    # Deletes files.
    #
    # @param [String] from
    # @param [Array<String>] files
    def delete(from, files)
      return unless File.exist?(from)

      @logger.debug("Deleting #{files.length} items from '#{from}'")
      FileUtils.cd(from) do
        files.each do |file|
          next unless File.exist?(file)
          @logger.fine("Deleting '#{file}'...")
          FileUtils.rm_r(file)
        end
      end
    end

    # Adds a file that needs to be processed.
    #
    # @param [String] package_dir
    # @param [String] framework_dir
    # @param [Array<String>] files
    def file(package_dir, framework_dir, *files)
      @items << [files, framework_dir, package_dir]
    end

  end

end
