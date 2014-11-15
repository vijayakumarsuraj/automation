#
# Suraj Vijayakumar
# 01 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'application'.
  class ApplicationPackage < Automation::Package

    # New application package.
    def initialize(name)
      @name = name

      super()

      @base = @config_manager['applications_directory']
    end

    private

    # Defines the files all packages MUST have.
    # Implementations refine this method further.
    def define
      lib('.', 'package.rb')
    end

    # Define application code / configuration files.
    #
    # @param [String] package_dir
    # @param [String] include
    # @param [String] exclude
    def lib(package_dir, include, exclude = '')
      files(package_dir, "#{Automation::APP_DIR}/#{@name}", include, exclude)
    end

  end

end