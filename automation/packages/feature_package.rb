#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'feature'.
  class FeaturePackage < Automation::Package

    # New feature package.
    def initialize
      super

      @base = @config_manager['features_directory']
    end

    private

    # Defines the files all packages MUST have.
    def define
      file('.', "#{Automation::FET_DIR}/#{@name}", 'package.rb')
    end

    # Define a file for the framework's 'Configuration' directory.
    #
    # @param [Array<String>] files
    def conf(package_dir, *files)
      file(package_dir, "Configuration/#{Automation::FET_DIR}", *files)
    end

    # Define feature code files.
    #
    # @param [Array<String>] files
    def lib(package_dir, *files)
      file(package_dir, "#{Automation::FET_DIR}/#{@name}", *files)
    end

  end

end
