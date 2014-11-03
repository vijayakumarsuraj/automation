#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'test_pack'.
  class TestPackPackage < Automation::Package

    PACKAGE_TYPE = 'test_pack'

    TEST_PACK_CODE_ZIP = 'test_pack.zip'

    # Uninstalls the specified test pack. All code will be deleted!
    #
    # @param [String] pack_name
    def self.uninstall(pack_name)
      config_manager = environment.config_manager

      test_pack_directory = File.join(config_manager['test_packs.directory'], pack_name)
      raise PackageError.new("Test pack directory '#{test_pack_directory}' does not exist") unless File.directory?(test_pack_directory)

      FileUtils.rm_rf(test_pack_directory)
    end

  end

end
