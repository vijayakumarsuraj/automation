#
# Suraj Vijayakumar
# 08 Jan 2013
#

require 'automation/core/component'

module Automation

  # Represents a mode that the framework can be executed in. Modes are self-sufficient tasks.
  # Each mode must provide a custom implementation of this base class.
  class Mode < Component

    # Returns a list of parent mode names for this mode.
    #
    # @param [String] mode the mode
    # @return [Array<String>] the parent modes.
    def self.mode_names(application, mode)
      return [] if mode.nil?

      require_file, class_name = Component.get_details(application, mode, Component::ModeType, mode)[0..1]
      require require_file
      clazz = constant(class_name)
      # Get the list of parent classes and convert each one to a mode name.
      names = [mode]
      superclasses(clazz).map { |sc| names.insert(0, sc.basename.underscore); break if sc.eql?(Mode) }
      names
    end

    module CommandLineOptions

      # Method for creating the config name option.
      def option_config_name
        block = proc { |config_name| save_option_value('run.config_name', config_name); propagate_option('--config', config_name) }
        @cl_parser.on('--build NAME', '--config NAME', 'Specify the name of the configuration to use.',
                      'If skipped, the default specified for the application is used.', &block)

        block = proc { |file_name| save_option_value('run.config_file', file_name); propagate_option('--config-file', file_name) }
        @cl_parser.on('--build-file NAME', '--config-file NAME', 'Specify the name of the configuration file to use.', &block)
      end

      # Method for creating the results database option.
      def option_results_database
        block = proc { |database| save_option_value('database.id', database); propagate_option('--database', database) }
        @cl_parser.on('--database ID', 'Specify the id of the databases to use.',
                      'If skipped, the default specified for the mode is used.', &block)

        block = proc { |database| save_option_value('database.results_database.database_id', database); propagate_option('--results-database', database) }
        @cl_parser.on('--results-database ID', 'Specify the id of the database to use.',
                      'If skipped, the default specified for the mode is used.', &block)
      end

      # Method for creating the help option.
      def option_help_tail
        block = proc { puts @cl_parser; exit }
        @cl_parser.on_tail('-h', '--help', 'Shows this message', &block)
      end

      # Method for creating the logging option.
      def option_logging
        block = proc { |level| Logging::Logger.root.level = level; propagate_option('--logging', level) }
        @cl_parser.on('--logging LEVEL', 'Specify the minimum log level that should be logged.', &block)
      end

      # Method for creating the observers option.
      def option_observers
        block = proc { |observers| observers.split(',').each { |observer| save_option_value("task.observer.#{observer}", nil) }; propagate_option('--observers', observers) }
        @cl_parser.on('--observers NAME1,NAME2', 'Enter a list of observers to use for this run.', &block)

      end

      # Method for creating the property option.
      def option_property
        block = proc do |key_and_value|
          hash = YAML.load(key_and_value)
          raise OptionParser::InvalidArgument.new('"' + key_and_value + '"') unless hash.kind_of?(Hash)
          #
          key = hash.keys[0]
          value = hash[key]
          save_option_value(key, value); propagate_option('--property', key_and_value)
        end
        @cl_parser.on('--property "KEY: VALUE"', 'Enter arbitrary property values.',
                      'Can be used multiple times for multiple properties.', &block)
      end

      # Method for creating the results archive option.
      def option_results_archive
        block = proc { |path| save_option_value('results.archive', path); propagate_option('--results-archive', path) }
        @cl_parser.on('--results-archive PATH', 'Specify the location of the results archive.', &block)
      end

      # Method for creating the run name option.
      def option_run_id
        block = proc { |name| save_option_value('run.name', name); propagate_option('--run-name', name) }
        @cl_parser.on('--run-name NAME', 'Override the name of the run.', &block)
      end

      # Method for creating a separator in the help summary.
      #
      # @param [String] text the text that will be displayed.
      def option_separator(text = '')
        @cl_parser.separator(text)
      end

      # Method for creating the version option.
      def option_version_tail
        block = proc { puts "#{FRAMEWORK_TITLE}"; exit }
        @cl_parser.on_tail('-v', '--version', 'Show version information', &block)
      end

    end

    # Include the default command line options.
    include Automation::Mode::CommandLineOptions
    # Makes this runnable.
    include Automation::Runnable


    # Accessor for the list of non-option arguments provided on the command lien.
    attr_reader :cl_non_options

    # New mode.
    def initialize
      super

      @result = Automation::Result::Pass
      @cl_parser = OptionParser.new(FRAMEWORK_TITLE, 40)
      @cl_options = @config_manager.get_configuration('command-line')
      @cl_propagate = []
      @cl_non_options = []

      @component_type = Automation::Component::ModeType
      @raise_exceptions = false
      @archive_results = false
      @databases = runtime.databases

      runtime.save(:mode, self)
    end

    private

    # The following steps are carried out (in no particular order):
    # 1. Close the file appender used by this mode.
    # 2. Zip and archive the run results.
    def cleanup
      close_file_appender
      archive_run_result if (defined? @results_archive) && @archive_results
    end

    # Executed if there are exceptions.
    # By default, logs the error and re-raises it.
    #
    # @param [Exception] ex the exception.
    def exception(ex)
      update_result(Automation::Result::Exception)
      @logger.error(format_exception(ex))
    end

    # The following steps are carried out (in no particular order):
    # 1. Connect to the results database.
    # 2. Load any application specific databases.
    def run
      create_file_appender
      # The first and ONLY place the results database is created and connected to.
      load_database
      # Create any application specific databases.
      load_application_database
    end

    # The following steps are carried out (in no particular order):
    # 1. Create the command line options that all modes support.
    # 2. Create the standard properties that all modes share.
    # 3. Create the result directory.
    # 4. Parse the command line options (checks if they are valid too).
    # 5. Create the file appender used by this mode.
    def setup
      add_standard_properties
      #
      create_banner
      create_standard_options
      create_advanced_options
      create_mode_options
      create_application_options
      create_feature_options
      create_tail_options
      #
      parse_options
      load_config_configuration
      create_result_directory
      load_results_archive
    end

    # Adds standard properties that all modes need.
    def add_standard_properties
      add_standard_property('run.start_date_time', DateTime.now.strftime(DateTimeFormat::SORTABLE_TIMESTAMP))
      add_standard_property('run.platform', ruby_platform)
    end

    # Archives the results of the current run.
    def archive_run_result
      @results_archive.save_run_result(@config_manager['run.name'])
    end

    # Closes the file appender of this mode.
    def close_file_appender
      if defined? @appender
        @appender.close
        Logging::Logger.root.remove_appenders(@appender)
      end
    end

    # Adds the advanced options that all modes support.
    def create_advanced_options
      option_separator
      option_separator 'Advanced options:'
      option_results_archive
      option_run_id
      option_observers
      option_property

      option_separator
      option_results_database
    end

    # Creates application specific options.
    def create_application_options
      option_separator
      option_separator 'Application specific options:'
    end

    # Creates the banner printed by the help message.
    def create_banner
      option_separator
      option_separator 'Usage: main.rb <application>-<mode> [options]'
    end

    # Creates feature specific options.
    def create_feature_options
      option_separator
      option_separator 'Feature options:'
    end

    # Configures the logger so that logs are sent to the required log file.
    def create_file_appender
      pattern = @config_manager['logging.file.pattern']
      date_pattern = @config_manager['logging.file.date_pattern']
      layout = Logging::Layouts::Pattern.new(pattern: pattern, date_pattern: date_pattern)
      #
      run_result_directory = @config_manager['run.result.directory']
      log_file = "#{run_result_directory}/#{log_file_name}.log"
      @appender = Logging::Appenders::File.new('file', filename: log_file, layout: layout)
      #
      Logging::Logger.root.add_appenders(@appender)
    end

    # Creates mode specific options.
    def create_mode_options
      option_separator
      option_separator 'Mode specific options:'
    end

    # Creates the results directory.
    def create_result_directory
      run_result_directory = @config_manager['run.result.directory']
      FileUtils.mkdir_p(run_result_directory)
    end

    # Adds the standard options that all modes support.
    def create_standard_options
      option_separator
      option_separator 'Standard options:'
      option_config_name
      option_logging
    end

    # Adds the tail options that all modes support.
    def create_tail_options
      @cl_parser.on_tail
      @cl_parser.on_tail 'Other options:'
      option_help_tail
      option_version_tail
    end

    # Loads the application specific database.
    def load_application_database
      application_name = @config_manager['run.application']
      method_name = :"load_#{application_name}_database"
      send(method_name) if respond_to?(method_name, true)
    end

    # Loads the build specific configuration.
    def load_config_configuration
      file_name = @config_manager['run.config_file', default: nil]
      return if file_name.nil?

      FileUtils.cd(FRAMEWORK_ROOT) { @config_manager.load_configuration('config', "Configuration/Builds/#{file_name}") }
    end

    # Loads the results database.
    def load_database
      @results_database = load_component(Component::CoreType, 'results_database')
      @results_database.connect
      # Migrate (i.e. recreate the db schema) as required.
      if @config_manager['database.results_database.recreate', default: false]
        @results_database.migrate!
      elsif @config_manager['database.results_database.migrate', default: false]
        @results_database.migrate
      end
      # Save the reference.
      @databases.results_database = @results_database
    end

    # Loads the results archive component.
    def load_results_archive
      @results_archive = load_component(Component::ResultDataType, 'results_archive')
      runtime.save(:results_archive, @results_archive)
    end

    # Get the name of the log file for this component.
    def log_file_name
      @component_name
    end

    # Parses all command line options.
    def parse_options
      @cl_non_options = @cl_parser.parse(ARGV)
    end

    # Marks the specified option for propagation - i.e. all modes launched by this mode will also 'see' such options.
    def propagate_option(option, value = nil)
      @cl_propagate << option
      @cl_propagate << value unless value.nil?
    end

    # Save the value of the specified option. Overwrites values if they already exist.
    #
    # @param [String] key the key that identifies the option.
    # @param [Object] value the value.
    # @param [Boolean] as_array if true, the value is stored in an array.
    def save_option_value(key, value, as_array = false)
      if as_array
        node = @cl_options.get_child?(key)
        node ? node.value << value : @cl_options.add_property(key, [value])
      else
        @cl_options.add_property(key, value, overwrite: true)
      end
    end

  end

end
