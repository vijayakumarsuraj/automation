#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'feature'.
  class FeaturePackage < Automation::Package

    # New feature package.
    def initialize(name)
      @name = name

      super()

      @base = @config_manager['features_directory']
    end

    private

    # Defines the files all packages MUST have.
    def define
      lib('lib', '{*,.*}', '{package.rb,.,..}')
      conf('conf', "#{@name}.yaml")

      super
    end

    # Define a file for the framework's Configuration/modes directory.
    #
    # @param [String] package_dir
    # @param [String] include
    def conf_mode(package_dir, include)
      files(package_dir, 'Configuration/modes', include, '')
    end

    # Define a file for the framework's 'Configuration/Features' directory.
    #
    # @param [String] package_dir
    # @param [String] include
    def conf(package_dir, include)
      files(package_dir, "Configuration/#{Automation::FET_DIR}", include, '')
    end

    # Define feature code files.
    #
    # @param [String] package_dir
    # @param [String] include
    # @param [String] exclude
    def lib(package_dir, include, exclude = '')
      files(package_dir, "#{Automation::FET_DIR}/#{@name}", include, exclude)
    end

  end

end
