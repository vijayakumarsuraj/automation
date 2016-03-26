#
# Suraj Vijayakumar
# 01 Mar 2013
#

require 'automation/core/component'

module Automation::Test

  # Represents a test pack.
  class TestPack < Automation::Component

    module TestFilters

      private

      # Filter the specified list of test names using the 'test.groups' property.
      #
      # @param [Array] test_names
      # @param [Array] values
      # @return [Array]
      def filter_by_group(test_names, values)
        test_names.select do |test_name|
          config = get_test_configuration(test_name)
          groups = config['test.groups', default: []]
          values.any? { |value| groups.any? { |group| group.match(value) } }
        end
      end

      # Filter the specified list of test names using the test's type (i.e. the classes it inherits from).
      #
      # @param [Array] test_names
      # @param [Array] values
      # @return [Array]
      def filter_by_type(test_names, values)
        test_names.select do |test_name|
          test_class = get_test_class(test_name)
          parents = superclasses(test_class)
          immediate_parent = parents[0]
          values.any? { |value| immediate_parent.name.match(value) }
        end
      end

    end

    # Provide methods for filtering test names.
    include TestFilters

    # New test pack.
    def initialize(root_directory)
      super()

      @root = root_directory
      @component_name = @component_name.snakecase
      @component_type = Automation::Component::CoreType

      @active_test_names = []
      @active_test_dependencies = {}
      @configurations = {}
    end

    # Returns a list of test names after applying the specified filter.
    #
    # @param [String] key the key to filter using (group or type)
    # @param [Array] values the values to filter on.
    # @param [Array] test_names optional list of test names to filter (default is to use all tests of this test pack)
    def filter_test_names(key, values, test_names = glob_test_names('*'))
      filter_method = "filter_by_#{key}"
      raise Automation::ExecutionError.new("Cannot apply filter '#{key}' - method '#{filter_method}' not found") unless respond_to?(filter_method, true)
      # Return the filtered list of test names.
      send(filter_method, test_names, values)
    end

    # Glob the specified test names into actual test directory names.
    #
    # @param [Array<String>] globs
    def glob_test_names(*globs)
      FileUtils.cd(@config_manager['test_pack.tests_directory']) do
        return globs.map { |glob| Dir.glob(glob) }.flatten.uniq
      end
    end

    # Gets the test represented by the specified test name.
    #
    # @param [String] test_name the name of the test to load.
    # @return [Test] the test object.
    def get_test(test_name)
      @test = get_test_class(test_name).new
      @test.name = test_name
      # Now load the extensions for this test.
      include_extensions(@test, 'test', test_name)
    end

    # Loads and returns the configuration object for the test with the specified name.
    # Does not re-load configurations that have already been loaded.
    # Returns an empty configuration if such a configuration does not exist.
    #
    # @param [String] test_name the name of the test.
    # @return [Configuration::SimpleConfiguration] the configuration object.
    def get_test_configuration(test_name)
      return Configuration::SimpleConfiguration.new unless File.directory?(@root)

      FileUtils.cd(@root) do
        unless @configurations.has_key?(test_name)
          config = Configuration::CombinedConfiguration.new
          load_test_application_configurations(test_name, config)
          load_test_configurations(test_name, config)
          config.add_configuration('global', @config_manager)
          @configurations[test_name] = config
        end
        # Return the configuration.
        return @configurations[test_name]
      end
    end

    # Returns all the dependencies (recursively, if required) for the specified test.
    #
    # @param [String] test_name the name of the test.
    # @param [Boolean] recursive if true, recursively identify dependant tests.
    # @return [Array<String>] the list of dependant test names.
    def get_test_dependencies(test_name, recursive = false)
      config = get_test_configuration(test_name)
      key = 'test.depends_on'
      # First get the dependencies for this test.
      dependencies = config.has_property?(key) ? config.get_value(key) : []
      if recursive
        # Then recursively get the dependencies for each dependency.
        recursive_dependencies = []
        dependencies.each { |dep_test_name| recursive_dependencies << get_test_dependencies(dep_test_name, true) }
        # Finally, flatten and filter a unique list of test names.
        (dependencies + recursive_dependencies).flatten.uniq
      else
        dependencies
      end
    end

    # Build the test dependencies hash.
    # This hash contains the immediate dependencies of each active test.
    #
    # @return [Hash] a hash where the key is the name of the test of the value is an array containing the dependencies of the test.
    def get_active_tests_dependencies
      @active_test_dependencies
    end

    # Get the names of the active tests in this test pack.
    # If no active tests have been specified, then returns the names of all tests.
    #
    # @return [Array] the list of active tests.
    def get_active_tests
      @active_test_names.length > 0 ? @active_test_names : glob_test_names('*')
    end

    # Loads all test pack specific configuration files.
    def load_configurations
      @config_manager.add_configuration('application-test', Configuration::SimpleConfiguration.new, 'application-end')
      @config_manager.add_configuration('test-pack-default', Configuration::SimpleConfiguration.new, 'feature-end')
      @config_manager.add_configuration('test-pack-mode', Configuration::SimpleConfiguration.new, 'feature-end')
      @config_manager.add_configuration('test-default', Configuration::SimpleConfiguration.new, 'feature-end')

      load_test_application_configurations
      load_test_pack_configurations
    end

    # Sets the list of active tests for this test pack.
    #
    # @param [Array] test_names the active test names.
    def set_active_tests(test_names)
      @active_test_names = test_names
      # Load the dependencies for each test.
      @active_test_dependencies.clear
      @active_test_names.each { |test_name| @active_test_dependencies[test_name] = get_test_dependencies(test_name) }
    end

    # Updates the load path so that test pack's libraries are available.
    def update_load_path
      $LOAD_PATH << @config_manager['test_pack.libraries_directory']
    end

    private

    # Get the class for the specified test.
    #
    # @param [String] test_name the name of the test.
    # @return [Class] the test's class.
    def get_test_class(test_name)
      test_file = @config_manager['test_pack.test_file', parameters: {'test.name' => test_name}]
      test_module = @config_manager['test_pack.test_module']
      test_module = test_module.empty? ? '' : "#{test_module}::"
      raise Automation::ExecutionError.new("Could not load test - File '#{test_file}' does not exist") unless File.exist?(test_file)
      # Require the test file and get a reference to the class.
      require test_file
      constant("#{test_module}#{test_name}")
    end

    # Loads the application specific configurations for the specified test.
    #
    # @param [String] test_name the test name.
    # @param [Configuration::CombinedConfiguration] configuration the configuration to load into.
    def load_test_application_configurations(test_name = @config_manager['test.name'], configuration = @config_manager)
      application = @config_manager['run.application']
      FileUtils.cd(Automation::FRAMEWORK_ROOT) do
        test_parent_names(test_name).each do |name|
          configuration.load_configuration('application-test', "#{APP_DIR}/#{application}/Configuration/tests/#{name}.yaml")
        end
      end
    end

    # Loads the configurations for the specified test.
    #
    # @param [String] test_name the test name.
    # @param [Configuration::CombinedConfiguration] configuration the configuration to load into.
    def load_test_configurations(test_name = @config_manager['test.name'], configuration = @config_manager)
      test_parent_names(test_name).each do |name|
        configuration.load_configuration('test-default', "Configuration/tests/#{name}.yaml")
      end
      configuration.load_configuration('test-default', "Tests/#{test_name}/#{test_name}.yaml")
    end

    # Loads the configurations for the test pack.
    def load_test_pack_configurations
      return unless File.directory?(@root)

      FileUtils.cd(@root) do
        @config_manager.load_configuration('test-pack-default', 'Configuration/default.yaml')
        load_test_pack_mode_configurations
        load_test_configurations
      end
    end

    # Loads the configurations for the test pack mode.
    def load_test_pack_mode_configurations
      application = @config_manager['run.application']
      mode = @config_manager['run.mode']
      Automation::Mode.mode_names(application, mode).each do |name|
        @config_manager.load_configuration('test-pack-mode', "Configuration/modes/#{name}.yaml")
      end
    end

    # Check if the specified test exists. This will only look for the .rb file for the specified test.
    #
    # @param [String] test_name the name of the test
    # @return [Boolean]
    def test_exists?(test_name)
      File.exist?(@config_manager['test_pack.test_file'])
    end

    # Returns a list of parent test names for this test.
    #
    # @param [String] test_name the mode
    # @return [Array<String>] the parent tests.
    def test_parent_names(test_name)
      return [] unless test_exists?(test_name)

      # Get the class for the specified test.
      # If there is no suitable class, return an empty array.
      clazz = get_test_class(test_name) rescue (return [])

      # Get the list of parent classes and convert each one to a mode name.
      names = []
      superclasses(clazz).map { |sc| names.insert(0, sc.basename.underscore); break if sc.eql?(Test) }
      names
    end

  end

end