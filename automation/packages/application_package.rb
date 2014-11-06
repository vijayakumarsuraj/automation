#
# Suraj Vijayakumar
# 01 Nov 2014
#

require 'automation/core/package'

module Automation

  # Represents a package of type 'application'.
  class ApplicationPackage < Automation::Package

    PACKAGE_TYPE = 'application'

    APP_CODE_ZIP = 'app.zip'

    # Uninstalls the specified application. All application code will be deleted!
    #
    # @param [String] app_name
    def self.uninstall(app_name)
      config_manager = environment.config_manager

      # Delete the application code.
      application_directory = File.join(config_manager['applications_directory'], app_name)
      FileUtils.rm_rf(application_directory)

      # Touch the framework's Gemfile - so that we force a 'bundle install'.
      root_directory = config_manager['root_directory']
      FileUtils.touch(File.join(root_directory, 'Gemfile'))
    end

    # Installs the application.
    def install
      type = package_type
      name = package_name
      raise PackageError.new("Invalid package type '#{type}' - expected '#{PACKAGE_TYPE}'") unless type.eql?(PACKAGE_TYPE)

      # Create a temporary directory for extracting stuff into.
      dir_name = File.basename(@file_path)
      app_package_directory = File.join(@working_directory, dir_name)
      FileUtils.rm_rf(app_package_directory) if File.directory?(app_package_directory)
      FileUtils.mkdir_p(app_package_directory)
      # Extract the app zip file.
      FileUtils.cd(app_package_directory) { seven_zip_extract(@file_path, APP_CODE_ZIP) }

      # Remove, if app directory exists.
      # NOTE: this will remove existing installations even if the extraction fails - probably okay though.
      application_directory = File.join(@config_manager['applications_directory'], name)
      if File.exist?(application_directory)
        @logger.warn("Found existing installation - removing '#{application_directory}'...")
        FileUtils.rm_rf(application_directory)
      end
      # Extract the app code now.
      FileUtils.mkdir_p(application_directory)
      app_package_file = File.join(app_package_directory, APP_CODE_ZIP)
      FileUtils.cd(application_directory) { seven_zip_extract(app_package_file) }

      # Touch the framework's Gemfile - so that we force a 'bundle install'.
      root_directory = @config_manager['root_directory']
      FileUtils.touch(File.join(root_directory, 'Gemfile'))
      # Delete the temporary directory we created.
      FileUtils.rm_rf(app_package_directory)
      # Return the name of the application that was installed.
      name
    end

    # Packages the specified application.
    #
    # @param [String] app_name
    # @param [Hash] package_details
    def package(app_name, package_details = {})
      defaults = {'package' => {}}
      package_details = defaults.merge(package_details)
      package_details['package']['name'] = app_name
      package_details['package']['type'] = PACKAGE_TYPE

      application_directory = File.join(@config_manager['applications_directory'], app_name)
      raise PackageError.new("Application directory '#{application_directory}' does not exist") unless File.directory?(application_directory)

      # Create a temporary directory for packaging stuff into.
      dir_name = File.basename(@file_path)
      app_package_directory = File.join(@working_directory, dir_name)
      FileUtils.rm_rf(app_package_directory) if File.directory?(app_package_directory)
      FileUtils.mkdir_p(app_package_directory)

      # Archive the app code.
      app_package_file = File.join(app_package_directory, APP_CODE_ZIP)
      FileUtils.cd(application_directory) { seven_zip_archive(app_package_file, '*') }
      # Create package.yaml
      package_yaml = File.join(app_package_directory, PACKAGE_CONFIG)
      File.open(package_yaml, 'w') { |f| f.puts(package_details.to_yaml) }

      # Archive the app code into <app_name>.zip
      # Put the package YAML file in there too.
      FileUtils.cd(app_package_directory) { seven_zip_archive(@file_path, app_package_file, package_yaml) }

      # Delete temp files.
      FileUtils.rm_rf(app_package_directory)
      # Return the package file we created.
      @file_path
    end

  end

end