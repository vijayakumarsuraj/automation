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
      @items = []

      define
    end

    # Installs this package.
    #
    # @param [String] from
    def install(from)
      uninstall
      # Copy all defined items into the framework.
      @items.each do |package_dir, to, include, exclude|
        from_path = File.join(from, package_dir)
        to_path = File.expand_path(to, @root)
        copy(from_path, include, exclude, to_path)
      end
      # So that the framework sets up it's gems the next time.
      FileUtils.touch(File.join(@root, 'Gemfile'))
    end

    # Creates this package.
    #
    # @param [String] to
    def package(to)
      @items.each do |package_dir, from, include, exclude|
        from_path = File.expand_path(from, @root)
        to_path = File.join(to, @name, package_dir)
        copy(from_path, include, exclude, to_path)
      end
    end

    # Uninstalls the package.
    def uninstall
      # Delete all explicitly defined files.
      @items.each do |_, from, include, exclude|
        from_path = File.expand_path(from, @root)
        delete(from_path, include)
      end
      # And the root directory.
      delete(@base, @name)
      # So that the framework sets up it's gems the next time.
      FileUtils.touch(File.join(@root, 'Gemfile'))
    end

    private

    # Defines code files - must be provided by implementations.
    #
    # @param [String] package_dir
    # @param [String] include
    # @param [String] exclude
    def lib(package_dir, include, exclude = '')
      raise NotImplementedError.new("Method 'lib' not implemented by '#{self.class.name}'")
    end

    # Defines the files contained in this package. Implementations must provide this method.
    def define
      lib('.', 'package.rb')
    end

    # Define a file for the framework's 'Bin' directory.
    #
    # @param [String] package_dir
    # @param [String] include
    # @param [String] exclude
    def bin(package_dir, include, exclude = '')
      files(package_dir, 'Bin', include, exclude)
    end

    # Copies files.
    #
    # @param [String] from
    # @param [String] include
    # @param [String] exclude
    # @param [String] to
    def copy(from, include, exclude, to)
      FileUtils.mkdir_p(to)
      FileUtils.cd(from) do
        files_include = Dir.glob(include)
        files_exclude = Dir.glob(exclude)
        files_copy(files_include - files_exclude, to)
      end
    end

    # Deletes files.
    #
    # @param [String] from
    # @param [String] pattern
    def delete(from, pattern)
      return unless File.exist?(from)

      FileUtils.cd(from) do
        files = Dir.glob(pattern)
        return if files.length == 0

        @logger.debug("Deleting #{files.length} items from '#{from}'")
        files.each do |file|
          @logger.fine("Deleting '#{file}'...")
          FileUtils.rm_r(file)
        end
      end
    end

    # Adds files that need to be processed.
    #
    # @param [String] package_dir
    # @param [String] framework_dir
    # @param [String] include_pattern
    # @param [String] exclude_pattern
    def files(package_dir, framework_dir, include_pattern, exclude_pattern = '')
      @items << [package_dir, framework_dir, include_pattern, exclude_pattern]
    end

  end

end
