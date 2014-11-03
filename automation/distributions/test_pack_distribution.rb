#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/distribution'

module Automation

  class TestPackDistribution < Automation::Distribution

    PACKAGE_TYPE = 'test_pack'

    TEST_PACK_CODE_ZIP = 'test_pack.zip'

    # Uninstalls the specified application. All application code will be deleted!
    #
    # @param [String] pack_name
    def self.uninstall(pack_name)
      config_manager = environment.config_manager

      test_pack_directory = File.join(config_manager['test_packs.directory'], pack_name)
      raise DistributionError.new("Test pack directory '#{test_pack_directory}' does not exist") unless File.directory?(test_pack_directory)

      FileUtils.rm_rf(test_pack_directory)
    end

  end

end
