#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/package'

module Automation::Test

  # Represents a package of type 'test_pack'.
  class TestPackPackage < Automation::Package

    # New test pack package.
    def initialize(name)
      @name = name

      super()

      @base = @config_manager['test_packs.directory']
    end

    private

    # Defines the files all packages MUST have.
    def define
      lib('.', 'package.rb')
    end

    # Define test pack code / configuration files.
    #
    # @param [String] package_dir
    # @param [String] include
    # @param [String] exclude
    def lib(package_dir, include, exclude = '')
      files(package_dir, File.join(@base, @name), include, exclude)
    end

  end

end
