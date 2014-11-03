#
# Suraj Vijayakumar
# 01 Nov 2014
#

require 'automation/core/component'

require 'automation/support/seven_zip_methods'

module Automation

  class DistributionError < Automation::Error
  end

  # Represents a abstract distribution.
  class Distribution < Automation::Component

    PACKAGE_CONFIG = 'package.yaml'

    include Automation::SevenZipMethods

    # Create a new distribution.
    #
    # @param [String] file_path
    def initialize(file_path)
      super()

      @dist_directory = @config_manager['dist.directory']
      @working_directory = @config_manager['run.working.directory']
      @file_path = File.expand_path(file_path, @dist_directory)

      @package_details = nil
    end

    # Installs this distribution. Implementations must provide this method.
    def install
      raise NotImplementedError.new("Method 'install' not implemented by '#{self.class.name}'")
    end

    # Package this distribution. Implementations must provide this method.
    def package
      raise NotImplementedError.new("Method 'package' not implemented by '#{self.class.name}'")
    end

    private

    # Extract and read the contents of the package.yaml file (if not already read).
    def package_details
      if @package_details.nil?
        create = false
        zip_file = Zip::File.open(@file_path, create)
        package_yaml = File.join(@working_directory, PACKAGE_CONFIG)
        zip_file.extract(PACKAGE_CONFIG, package_yaml)
        @package_details = YAML.load_file(package_yaml)
        FileUtils.rm_f(package_yaml)
      end

      @package_details
    end

    # The name of the package.
    def package_name
      package_details['package']['name']
    end

    # The type of the package.
    def package_type
      package_details['package']['type']
    end

  end

end
