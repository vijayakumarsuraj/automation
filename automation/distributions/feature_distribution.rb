#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'automation/core/distribution'

module Automation

  # Represents a distribution of type 'feature'.
  class FeatureDistribution < Automation::Distribution

    PACKAGE_TYPE = 'feature'

    FEATURE_CODE_ZIP = 'feature.zip'
    FEATURE_CONFIG = 'feature.yaml'

    # Uninstalls the specified feature. All feature code will be deleted!
    #
    # @param [String] app_name
    def self.uninstall(app_name)
      config_manager = environment.config_manager

      feature_directory = File.join(config_manager['features_directory'], app_name)
      raise DistributionError.new("Feature directory '#{feature_directory}' does not exist") unless File.directory?(feature_directory)
      feature_config = File.join(config_manager['root_directory'], 'Configuration', Automation::FET_DIR, "#{app_name}.yaml")
      raise DistributionError.new("Feature configuration '#{feature_config}' does not exist") unless File.exist?(feature_config)

      FileUtils.rm_rf([feature_directory, feature_config])
    end

    # Installs the feature.
    def install
      type = package_type
      name = package_name
      raise PackageError.new("Invalid package type '#{type}' - expected '#{PACKAGE_TYPE}'") unless type.eql?(PACKAGE_TYPE)

      # Create a temporary directory for extracting stuff into.
      dir_name = File.basename(@file_path)
      feature_dist_directory = File.join(@working_directory, dir_name)
      FileUtils.rm_rf(feature_dist_directory) if File.directory?(feature_dist_directory)
      FileUtils.mkdir_p(feature_dist_directory)
      # Extract the feature files.
      FileUtils.cd(feature_dist_directory) { seven_zip_extract(@file_path, FEATURE_CODE_ZIP, FEATURE_CONFIG) }

      # Remove, if feature directory exists.
      # NOTE: this will remove existing installations even if the extraction fails - probably okay though.
      feature_directory = File.join(@config_manager['features_directory'], name)
      if File.exist?(feature_directory)
        @logger.warn("Found existing installation - removing '#{feature_directory}'...")
        FileUtils.rm_rf(feature_directory)
      end
      # Extract the feature code now.
      FileUtils.mkdir_p(feature_directory)
      feature_file = File.join(feature_dist_directory, FEATURE_CODE_ZIP)
      FileUtils.cd(feature_directory) { seven_zip_extract(feature_file) }

      # Copy the feature config file.
      feature_config_src = File.join(feature_dist_directory, FEATURE_CONFIG)
      feature_config_dest = File.join(@config_manager['root_directory'], 'Configuration', Automation::FET_DIR, "#{name}.yaml")
      FileUtils.cp(feature_config_src, feature_config_dest)

      # Delete the temporary directory we created.
      FileUtils.rm_rf(feature_dist_directory)

      # Return the name of the feature that was installed.
      name
    end

    # Packages the specified feature.
    #
    # @param [String] feature_name
    # @param [Hash] package_details
    def package(feature_name, package_details = {})
      defaults = {'package' => {}}
      package_details = defaults.merge(package_details)
      package_details['package']['name'] = feature_name
      package_details['package']['type'] = PACKAGE_TYPE

      feature_directory = File.join(@config_manager['features_directory'], feature_name)
      raise DistributionError.new("Feature directory '#{feature_directory}' does not exist") unless File.directory?(feature_directory)
      feature_config = File.join(@config_manager['root_directory'], 'Configuration', Automation::FET_DIR, "#{feature_name}.yaml")
      raise DistributionError.new("Feature configuration '#{feature_config}' does not exist") unless File.exist?(feature_config)

      # Create a temporary directory for packaging stuff into.
      dir_name = File.basename(@file_path)
      feature_dist_directory = File.join(@working_directory, dir_name)
      FileUtils.rm_rf(feature_dist_directory) if File.directory?(feature_dist_directory)
      FileUtils.mkdir_p(feature_dist_directory)

      # Archive the feature code.
      feature_dist_file = File.join(feature_dist_directory, FEATURE_CODE_ZIP)
      FileUtils.cd(feature_directory) { seven_zip_archive(feature_dist_file, '*') }
      # Copy feature config.
      feature_config_dist_file = File.join(feature_dist_directory, FEATURE_CONFIG)
      FileUtils.cp(feature_config, feature_config_dist_file)
      # Create package.yaml
      package_yaml = File.join(feature_dist_directory, PACKAGE_CONFIG)
      File.open(package_yaml, 'w') { |f| f.puts(package_details.to_yaml) }

      # Archive the feature code and config.
      # Put the package YAML file in there too.
      FileUtils.cd(feature_dist_directory) { seven_zip_archive(@file_path, feature_dist_file, feature_config_dist_file, package_yaml) }

      # Delete temp files.
      FileUtils.rm_rf(feature_dist_directory)
      # Return the distribution file we created.
      @file_path
    end

  end

end
