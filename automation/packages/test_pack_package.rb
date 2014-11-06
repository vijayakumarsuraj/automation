#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'test_pack'.
  class TestPackPackage < Automation::Package

    PACKAGE_TYPE = 'test_pack'

    TEST_PACK_CODE_ZIP = 'tests.zip'

    # Uninstalls the specified test pack. All code will be deleted!
    #
    # @param [String] pack_name
    def self.uninstall(pack_name)
      config_manager = environment.config_manager

      test_pack_directory = File.join(config_manager['test_packs.directory'], pack_name)
      raise PackageError.new("Test pack directory '#{test_pack_directory}' does not exist") unless File.directory?(test_pack_directory)
      FileUtils.rm_rf(test_pack_directory)

      # Touch the framework's Gemfile - so that we force a 'bundle install'.
      root_directory = config_manager['root_directory']
      FileUtils.touch(File.join(root_directory, 'Gemfile'))
    end

    # Installs the test pack.
    def install
      type = package_type
      name = package_name
      raise PackageError.new("Invalid package type '#{type}' - expected '#{PACKAGE_TYPE}'") unless type.eql?(PACKAGE_TYPE)

      # Create a temporary directory for extracting stuff into.
      dir_name = File.basename(@file_path)
      tests_package_directory = File.join(@working_directory, dir_name)
      FileUtils.rm_rf(tests_package_directory) if File.directory?(tests_package_directory)
      FileUtils.mkdir_p(tests_package_directory)
      # Extract the test pack zip file.
      FileUtils.cd(tests_package_directory) { seven_zip_extract(@file_path, TEST_PACK_CODE_ZIP) }

      # Remove, if test pack directory exists.
      # NOTE: this will remove existing installations even if the extraction fails - probably okay though.
      test_pack_directory = File.join(@config_manager['test_packs.directory'], name)
      if File.exist?(test_pack_directory)
        @logger.warn("Found existing installation - removing '#{test_pack_directory}'...")
        FileUtils.rm_rf(test_pack_directory)
      end
      # Extract the tests code now.
      FileUtils.mkdir_p(test_pack_directory)
      tests_package_file = File.join(tests_package_directory, TEST_PACK_CODE_ZIP)
      FileUtils.cd(test_pack_directory) { seven_zip_extract(tests_package_file) }

      # Touch the framework's Gemfile - so that we force a 'bundle install'.
      root_directory = @config_manager['root_directory']
      FileUtils.touch(File.join(root_directory, 'Gemfile'))
      # Delete the temporary directory we created.
      FileUtils.rm_rf(tests_package_directory)
      # Return the name of the test pack that was installed.
      name
    end

    # Packages the specified test pack.
    #
    # @param [String] test_pack_name
    # @param [Hash] package_details
    def package(test_pack_name, package_details = {})
      defaults = {'package' => {}}
      package_details = defaults.merge(package_details)
      package_details['package']['name'] = test_pack_name
      package_details['package']['type'] = PACKAGE_TYPE

      test_pack_directory = File.join(@config_manager['test_packs.directory'], test_pack_name)
      raise PackageError.new("Test pack directory '#{test_pack_directory}' does not exist") unless File.directory?(test_pack_directory)

      # Create a temporary directory for packaging stuff into.
      dir_name = File.basename(@file_path)
      tests_package_directory = File.join(@working_directory, dir_name)
      FileUtils.rm_rf(tests_package_directory) if File.directory?(tests_package_directory)
      FileUtils.mkdir_p(tests_package_directory)

      # Archive the test pack code.
      tests_package_file = File.join(tests_package_directory, TEST_PACK_CODE_ZIP)
      FileUtils.cd(test_pack_directory) { seven_zip_archive(tests_package_file, '*') }
      # Create package.yaml
      package_yaml = File.join(tests_package_directory, PACKAGE_CONFIG)
      File.open(package_yaml, 'w') { |f| f.puts(package_details.to_yaml) }

      # Archive the test pack code into <test pack>.zip
      # Put the package YAML file in there too.
      FileUtils.cd(tests_package_directory) { seven_zip_archive(@file_path, tests_package_file, package_yaml) }

      # Delete temp files.
      FileUtils.rm_rf(tests_package_directory)
      # Return the package file we created.
      @file_path
    end

  end

end
