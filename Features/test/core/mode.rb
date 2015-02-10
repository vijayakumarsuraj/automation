#
# Suraj Vijayakumar
# 19 Jan 2015
#

require 'automation/core/mode'

module Automation

  # Overrides for when the 'test' feature is enabled.
  class Mode < Component

    module CommandLineOptions

      private

      # Method for creating the run group option.
      def option_run_group
        block = proc { |group| save_option_value('test.groups', group, true) }
        @cl_parser.on('--test-group NAME', 'Specify a test group to run.',
                      'Use multiple times for more than one group.', &block)
      end

      # Method for creating the test pack option.
      def option_test_pack
        block = proc { |test_pack| save_option_value('test_pack.name', test_pack); propagate_option('--test-pack', test_pack) }
        @cl_parser.on('--test-pack NAME', 'Specify the name of the test pack to use.',
                      'If skipped, the default specified for the application is used.', &block)
      end

    end

    private

    # Creates feature specific options.
    def create_feature_options_with_test_mode
      create_feature_options_without_test_mode

      option_test_pack
      option_run_group
    end

    # Chained to connect to the test database.
    def load_database_with_test_mode
      # First the default behaviour.
      load_database_without_test_mode
      # Then load the 'test' database.
      @test_database = load_component(Component::DatabaseType, 'test_database')
      @test_database.connect
      # Migrate (i.e. recreate the db schema) as required.
      if @config_manager['database.test_database.recreate', default: false]
        @test_database.migrate!
      elsif @config_manager['database.test_database.migrate', default: false]
        @test_database.migrate
      end
      @databases['test'] = @test_database
    end

    # The following steps are carried out (in no particular order):
    # 1. Loads and configures the test pack.
    def setup_with_test_mode
      setup_without_test_mode

      load_test_pack
      configure_test_pack
    end

    alias_method_chain :create_feature_options, :test_mode
    alias_method_chain :load_database, :test_mode
    alias_method_chain :setup, :test_mode

    # Overrides the default banner.
    def create_banner
      option_separator
      option_separator 'Usage: main.rb <application>-<mode> [options] [tests]'
      option_separator 'If no test names are specified, all tests are executed.'
    end

    # Configures the test pack for the test(s) that are being executed.
    def configure_test_pack
      length = @test_names.length
      @logger.info("Selected tests: #{@test_names.join(', ')}") if (length > 0 && length <= 5)
      @logger.info("Selected #{length} test(s)") if length > 5
      @test_pack.set_active_tests(@test_names)
      @test_dependencies = @test_pack.get_active_tests_dependencies
    end

    # Loads the test pack.
    def load_test_pack
      # Load the test pack.
      test_pack_directory = @config_manager['test_pack.directory']
      @test_pack = load_component(Component::CoreType, 'test_pack', test_pack_directory)
      runtime.save(:test_pack, @test_pack)
      # The test names as provided on the command line.
      @cl_non_options = ['*'] if @cl_non_options.length == 0
      @test_names = @test_pack.glob_test_names(*@cl_non_options)
      # The test name (if only one test is being executed).
      @test_name = @test_names.length == 1 ? @test_names[0] : '[MULTIPLE]'
      add_standard_property('test.name', @test_name, overwrite: true)
      # Initialize the test pack.
      @test_pack.update_load_path
      @test_pack.load_configurations
    end

  end

end
