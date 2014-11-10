#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'test_pack'.
  class TestPackPackage < Automation::Package

    # New test pack package.
    def initialize
      super

      @base = @config_manager['test_packs.directory']
    end

    private

    # Defines the files all packages MUST have.
    def define
      file('.', "#{@base}/#{@name}", 'package.rb')
    end

    # Define test pack code / configuration files.
    #
    # @param [Array<String>] files
    def lib(package_dir, *files)
      file(package_dir, File.join(@base, @name), *files)
    end

  end

end
