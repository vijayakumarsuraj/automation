#
# Suraj Vijayakumar
# 02 Dec 2012
#

require 'configuration/error'
require 'configuration/simple_configuration'
require 'configuration/yaml_configuration'

module Configuration

  class CombinedConfiguration < SimpleConfiguration

    # New empty combined configuration.
    def initialize
      super

      @configuration_names = []
      @configurations = {}
      @ignore_events = false
      # Change listener.
      @listener = Proc.new do |event, *args|
        # Do nothing if the ignore events flag was set.
        next if @ignore_events
        case event
          when 'child_added'
            refresh(args[0])
          else
            raise ConfigurationError.new("Unhandled event '#{event}'")
        end
      end
    end

    # Adds a child configuration to this configuration.
    #
    # @param [String] name a unique identifier for this configuration.
    # @param [SimpleConfiguration] configuration the configuration to add.
    # @param [Integer, String] position the position where the configuration should be added.
    #   An integer value specifies the index to add the configuration to.
    #   A string value specifies identifies the configuration before which this configuration should be added.
    #   If not specified or if an invalid value is specified, adds the configuration at the end.
    def add_configuration(name, configuration, position = nil)
      raise KeyError.new("Configuration '#{name}' already exists") if @configurations.has_key?(name)
      # If position is a String, find the configuration with the specified name. And use it's position.
      position = @configuration_names.index(position) if position.kind_of?(String)
      # Default to -1.
      position = -1 if position.nil?
      # Save the configuration.
      @configurations[name] = configuration
      @configuration_names.insert(position, name)
      # Add a listener.
      configuration.add_listener(@listener)
      # Clear the current configuration tree and then refresh the whole tree.
      clear
      refresh
    end

    # Get the configuration identified by the specified name.
    #
    # @param [String] name the configuration to get.
    # @return [SimpleConfiguration] the configuration.
    def get_configuration(name)
      raise KeyError.new("Configuration '#{name}' does not exist") unless @configurations.has_key?(name)
      @configurations[name]
    end

    # Loads the specified configuration file into this combined configuration.
    #
    # @param [String] name a unique name for this configuration.
    # @param [Array<String>] files the files to load.
    def load_configuration(name, *files)
      files.each do |file|
        if not File.exist?(file)
          update_configuration(name, Configuration::SimpleConfiguration.new)
        elsif %w(.yaml .yml).include?(File.extname(file).downcase)
          @logger.finer("Loading '#{file}' as '#{name}'...") if defined? @logger
          update_configuration(name, Configuration::YamlConfiguration.new(file))
        else
          raise IOError.new("Don't know how to load property file '#{file}'")
        end
      end
    end

    # Deletes the specified configuration. The configuration tree won't be updated unless 'refresh' is also invoked.
    #
    # @param [String] name the configuration to delete.
    # @return [SimpleConfiguration] the configuration that was deleted, or nil if no such configuration exists.
    def remove(name)
      @configuration_names.delete(name)
      @configurations.delete(name)
      # Clear the current configuration tree and then refresh the whole tree.
      clear
      refresh
    end

    # Adds a configuration to this configuration. If a configuration with the specified name already exists,
    # it is updated merging it with this one.
    #
    # @param [String] name a unique identifier for this configuration.
    # @param [SimpleConfiguration] configuration the configuration to add.
    def update_configuration(name, configuration)
      # Add if this configuration does not exist.
      return add_configuration(name, configuration) unless @configurations.has_key?(name)
      # Update.
      @configurations[name].merge!(configuration)
      # Now clear and refresh the whole configuration.
      clear
      refresh
    end

    private

    # Refreshes this configuration.
    #
    # @param [Node] node the node to apply the refresh for.
    def refresh(node = nil)
      key = node.nil? ? '' : node.full_name
      @configuration_names.each { |name| merge!(@configurations[name], key) }
    end

  end

end
