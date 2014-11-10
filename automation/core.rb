#
# Suraj Vijayakumar
# 08 Mar 2013
#

require 'logging'
require 'timeout'

require 'active_record'
require 'active_support/inflector'

require 'activerecord-import'
require 'squeel'

require 'rexml/document'
require 'rexml/formatters/pretty'

require 'zip'
require 'zip/filesystem'

require 'facets/enumerable/map_with_index'
require 'facets/file/write'
require 'facets/module/alias_method_chain'
require 'facets/module/basename'
require 'facets/numeric/round'
require 'facets/kernel/constant'
require 'facets/string/camelcase'
require 'facets/string/snakecase'
require 'facets/string/titlecase'
require 'facets/string/underscore'

require 'configuration/combined_configuration'
require 'configuration/simple_configuration'
require 'configuration/yaml_configuration'

require 'concurrent/thread_pool'

module Automation

  FRAMEWORK_NAME = 'Automation Test Framework'
  FRAMEWORK_MAJOR_VERSION = 4
  FRAMEWORK_MINOR_VERSION = 1
  FRAMEWORK_TITLE = "#{FRAMEWORK_NAME} v#{FRAMEWORK_MAJOR_VERSION}.#{FRAMEWORK_MINOR_VERSION}"

  # Configure the framework.
  # Should be called exactly once!
  def self.configure(application, mode)
    ActiveSupport::LogSubscriber.colorize_logging = false
    # Custom plurals. So that component loading can find these components.
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.irregular 'result_data', 'result_data'
      inflect.irregular 'core', 'core'
    end
    # Starts the framework's thread pool.
    thread_pool = Concurrent::ThreadPool.new(4, 'Automation::ThreadPool')
    environment.save(:thread_pool, thread_pool)
    # Other environment variables.
    environment.save(:number_of_processors, [ENV['NUMBER_OF_PROCESSORS'].to_i, 1].max)
    environment.save(:logger, Logging::Logger['Automation'])
    environment.save(:hostname, Socket.gethostbyname('localhost').first)
    environment.save(:databases, Automation::Databases.new)
    # Standard properties.
    add_standard_property('pwd', FRAMEWORK_PWD)
    add_standard_property('root_directory', FRAMEWORK_ROOT)
    add_standard_property('root_directory_win', Converter.to_windows_path(FRAMEWORK_ROOT))
    add_standard_property('applications_directory', File.join(FRAMEWORK_ROOT, APP_DIR))
    add_standard_property('libraries_directory', File.join(FRAMEWORK_ROOT, LIB_DIR))
    add_standard_property('features_directory', File.join(FRAMEWORK_ROOT, FET_DIR))
    add_override_property('run.application', application)
    add_override_property('run.mode', mode)
    add_override_property('run.pid', $$)
    # Environment singleton store.
    environment.save(:loaded_components, {})
  end

  # Expands the specified application into a full application name.
  # e.g. west will be expanded to westminster, pnl will be expanded to pnl_explain, etc.
  #
  # If the specified application cannot be expanded, either because there were no matches, or because there was more than
  # one match, throw an exception.
  #
  # @param [String] application
  def self.expand_application(application)
    applications = supported_applications
    # First check for an exact match.
    return application if applications.include?(application)
    # No exact match, so look for a prefix match.
    expanded = nil
    one_match = supported_applications.one? do |item|
      if item.start_with?(application)
        expanded = item
        true
      else
        false
      end
    end
    # If there was a prefix match, return it. Otherwise raise an exception.
    raise "Application '#{application}' could not be resolved into a supported application" unless one_match
    expanded
  end

  # Gets a list of supported application names.
  #
  # @return [Array<String>] the list of supported applications.
  def self.supported_applications
    FileUtils.cd(File.join(FRAMEWORK_ROOT, 'Applications')) { return Dir.glob('*') }
  end

  # Gets a list of modes supported for the specified application.
  #
  # @return [Array<String>] the list of supported modes.
  def self.supported_modes
    modes = []
    config_manager = environment.config_manager
    config_manager.get_child?('mode').each_child { |child| modes << [child.name, child.get_value('description')] }
    modes
  end

  # Private methods that should not be invoked!

  # Configures the framework's logging.
  def self.configure_logging
    config_manager = environment.config_manager

    Logging.configure do
      pre_config do
        levels %w[TRACE FINER FINE DEBUG CONF INFO TEST_INFO WARN ERROR FATAL]
      end

      logger('root') do
        level :all
        appenders 'stdout'
      end

      appender('stdout') do
        level config_manager['logging.console.level']
        type 'Stdout'
        layout do
          type 'Pattern'
          pattern config_manager['logging.console.pattern']
          date_pattern config_manager['logging.console.date_pattern']
        end
      end
    end
    # Initialise...
    Logging.ndc.push('main-thread')
    config_manager.instance_variable_set(:@logger, Logging::Logger['Automation::ConfigManager'])
  end

  # Get the automation environment.
  def self.environment
    Environment.instance
  end

  # Loads the default configuration file.
  def self.load_default_configuration
    FileUtils.cd(FRAMEWORK_ROOT) do
      config_manager = environment.config_manager
      config_manager.load_configuration('default', 'Configuration/default.yaml')
      config_manager.load_configuration('feature', *Dir.glob("Configuration/#{Automation::FET_DIR}/*.yaml"))
      config_manager.add_configuration('application-default', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('mode', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('application-mode', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('application-test', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('test-pack-default', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('test-pack-mode', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('test-default', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('config', Configuration::SimpleConfiguration.new)
      config_manager.load_configuration('user', 'Configuration/user.yaml')
      config_manager.add_configuration('command-line', Configuration::SimpleConfiguration.new)
      config_manager.add_configuration('override', Configuration::SimpleConfiguration.new)
    end
  end

  # Loads all application / mode configuration files.
  def self.load_configurations(application, mode)
    FileUtils.cd(FRAMEWORK_ROOT) do
      config_manager = environment.config_manager
      config_manager.load_configuration('application-default', "#{APP_DIR}/#{application}/Configuration/default.yaml")
      # Load all mode and parent mode configurations.
      mode_names = Mode.mode_names(application, mode)
      mode_names.each { |name| config_manager.load_configuration('mode', "Configuration/modes/#{name}.yaml") }
      mode_names.each { |name| config_manager.load_configuration('application-mode', "#{APP_DIR}/#{application}/Configuration/modes/#{name}.yaml") }
    end
  end

end

require 'automation/error'

require 'automation/bootstrap/config_manager'

require 'automation/core/component'
require 'automation/core/assertion'
require 'automation/core/databases'
require 'automation/core/task'
require 'automation/core/mode'
require 'automation/core/test'
require 'automation/core/test_pack'

require 'automation/assertions/boolean'
require 'automation/assertions/file'
require 'automation/assertions/null'
require 'automation/assertions/operator'

require 'automation/result_data/run_result_data'
require 'automation/result_data/task_result_data'

require 'automation/util/converter'
require 'automation/util/date_time_format'
require 'automation/util/windows'
