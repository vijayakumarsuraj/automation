#
# Suraj Vijayakumar
# 27 Dec 2012
#

require 'yaml'

require 'configuration/simple_configuration'

module Configuration

  class YamlConfiguration < SimpleConfiguration

    # The underlying file this configuration reads from.
    attr_reader :file

    # New YAML configuration where properties are loaded from the specified YAML file.
    #
    # @param [String] file the file to load properties from.
    def initialize(file)
      super(load_file(file))

      @file = file
    end

    private

    # Loads the specified file and returns the properties as a hash.
    #
    # @param [String] file the file to load.
    def load_file(file)
      # Includes are resolved relative to their parent.
      dir, _ = File.split(file)
      # Load the properties from the file as a hash.
      raise IOError.new("File '#{file}' does not exist") unless File.exist?(file)
      properties = YAML.load_file(file)
      # If there were no properties to load, return an empty hash.
      return {} unless properties
      # Load any included files (recursively).
      if properties.has_key?('include')
        include_files = properties.delete('include')
        include_files = [include_files] unless include_files.kind_of?(Array)
        include_files.each do |include_file|
          include_file = File.expand_path(include_file, dir)
          include_properties = load_file(include_file)
          properties = deep_merge(properties, include_properties)
        end
      end
      # All done so return the fully loaded properties hash.
      properties
    end

  end

end