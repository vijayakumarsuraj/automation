#
# Suraj Vijayakumar
# 01 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'application'.
  class ApplicationPackage < Automation::Package

    # New application package.
    def initialize
      super

      @base = @config_manager['applications_directory']
    end

    private

    # Defines the files all packages MUST have.
    def define
      file('.', "#{Automation::APP_DIR}/#{@name}", 'package.rb')
    end

    # Define application code / configuration files.
    #
    # @param [Array<String>] files
    def lib(package_dir, *files)
      file(package_dir, "#{Automation::APP_DIR}/#{@name}", *files)
    end

  end

end