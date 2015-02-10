#
# Suraj Vijayakumar
# 04 Dec 2012
#

include Automation::Kernel

# Defines the CombinedConfiguration that is used by the framework.
config_manager = Configuration::CombinedConfiguration.new
config_manager.add_configuration('standard', Configuration::SimpleConfiguration.new)
# Add additional methods.
class << config_manager

  attr_reader :logger

  # Special override of the 'load_configuration' method that will attempt to load the platform specific configuration
  # file also.
  def load_configuration_with_platform(name, *files)
    files.each do |file|
      # First load the usual configuration file.
      load_configuration_without_platform(name, file)
      # Then attempt to load the platform specific one.
      ext = File.extname(file)
      dir = File.dirname(file)
      base = File.basename(file, ext)
      filename = "#{base}.#{ruby_platform}#{ext}"
      file = File.join(dir, filename)
      load_configuration_without_platform(name, file)
    end
  end

  alias_method_chain :load_configuration, :platform

  # Adds a property to the override configuration of the config manager.
  #
  # @param [String] key the key that identifies this property.
  # @param [Object] value the value.
  def add_override_property(key, value, overrides = {})
    # Create it if required.
    @override_config = get_configuration('override') unless defined? @override_config
    @override_config.add_property(key, value, overrides)
  end

  # Adds a property to the standard configuration of the config manager.
  #
  # @param [String] key the key that identifies this property.
  # @param [Object] value the value.
  def add_standard_property(key, value, overrides = {})
    # Create it if required.
    @standard_config = get_configuration('standard') unless defined? @standard_config
    @standard_config.add_property(key, value, overrides)
  end

end

runtime.save(:config_manager, config_manager)
