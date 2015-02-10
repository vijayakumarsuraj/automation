#
# Suraj Vijayakumar
# 19 Jan 2015
#

require 'automation/modes/runner'

module Automation

  # Overrides for when the 'test' feature is enabled.
  class Runner < Mode

    module CommandLineOptions

      def option_filter
        block = proc { |key_value| key, value = key_value.split('=', 2); @test_filters[key.downcase] << value }
        @cl_parser.on('--pick-test KEY=VALUE', 'Specify a criteria to select which tests should be executed.',
                      'Available selection keys are: "group", "type"',
                      'Can be used multiple times.', &block)

        block = proc { |value| @test_filters['group'] << value }
        @cl_parser.on('--pick-test-group GROUP', 'Equivalent to the above option for the key "group".', &block)

        block = proc { |value| @test_filters['type'] << value }
        @cl_parser.on('--pick-test-type TYPE', 'Equivalent to the above option for the key "type".', &block)
      end

    end

    module TaskGroupMethods

      # Generates the tasks of the group 'tests'.
      #
      # @param [Array] tasks the list of tasks of this group.
      def process_tasks_targets(tasks)
        @logger.finer('Sorting tests by priority...')
        tasks = tasks.sort { |t1, t2| get_test_priority(t2) <=> get_test_priority(t1) }

        @logger.finer('Generating test tasks...')
        tasks.each do |test_name|
          depends_on = @test_dependencies[test_name]
          depends_on = [] if depends_on.nil?
          overrides = {task_name: test_name, args: [test_name], depends_on: depends_on}
          task_name = @test_pack.get_test_configuration(test_name)['test.runner', default: 'test_runner']
          process_task(task_name, 'tests', overrides)
        end
      end

      # Get the tasks for the group 'tests'.
      #
      # @return [Array] the list of test names.
      def get_tasks_targets
        @test_pack.get_active_tests
      end

    end

    include TaskGroupMethods

    # Feature specific constructor override.
    def initialize_with_test_runner
      initialize_without_test_runner

      @test_priorities = {}
      @test_filters = Hash.new { |h, k| h[k] = [] }
    end

    alias_method_chain :initialize, :test_runner

    private

    # Feature specific cleanup.
    # 1. Cleans up any running tests.
    def cleanup_with_test_runner
      cleanup_without_test_runner

      if defined? @run_result
        # Any tests that are still "running" are marked as complete.
        # Their results are set to "unknown" too.
        test_results = @test_database.get_running_test_results(@run_result)
        test_results.each do |test_result|
          test_result.status = Status::Complete
          test_result.result = Result::Unknown
          test_result.save
        end
      end
    end

    # Feature specific command line options.
    def create_feature_options_with_test_runner
      create_feature_options_without_test_runner

      option_filter
    end

    alias_method_chain :create_feature_options, :test_runner

    # Overridden to include dependent tests while configuring the test pack.
    def configure_test_pack
      # Apply the required set of filters to the selected tests iteratively.
      @logger.debug('Applying test selection filters...')
      @test_filters.each_pair { |key, values| @test_names = @test_pack.filter_test_names(key, values, @test_names) }
      # Update the list of tests with implicit includes (due to dependencies).
      @logger.debug('Checking for dependencies...')
      implicit_includes = []
      @test_names.each { |test_name| implicit_includes << @test_pack.get_test_dependencies(test_name, true) }
      @test_names = [@test_names + implicit_includes].flatten.uniq
      # Validate if the list of selected tests are valid.
      validate_selected_tests
      # Configure the test pack with the new list of test names.
      super
    end

    # Gets the weight of a test (higher the weight, the higher the priority)
    # The default implementation will return the moving average (in seconds) of the last 10 runs of this test.
    # If no previous runs were found returns Float::MAX
    def get_test_priority(test_name)
      unless @test_priorities.has_key?(test_name)
        priority = @test_database.get_test_average_time(test_name, 10, Float::MAX)
        @test_priorities[test_name] = priority
      end

      @test_priorities[test_name]
    end

    # Validates if the @selected_test_names list is valid.
    # The default behaviour only checks to see if at least 1 test was selected.
    def validate_selected_tests
      raise ExecutionError.new('No tests were selected') if @test_names.length == 0
    end

  end

end
