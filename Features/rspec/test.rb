#
# Suraj Vijayakumar
# 26 Nov 2013
#

require 'rspec'
require 'rspec/core/formatters/base_formatter'

require 'test/core/test'

module Automation::Rspec

  class Formatter < RSpec::Core::Formatters::BaseFormatter

    # Access to framework methods.
    include Automation::Kernel

    # Register this class as a formatter for RSpec.
    # Currently it will handle only the following messages :
    # example_failed - notifies the current 'test_runner' that an example failed.
    RSpec::Core::Formatters.register(self, :example_failed)

    # New RSpec formatter.
    def initialize(output)
      super

      @logger = Logging::Logger[self]
      @runner = runtime.test_runner
    end

    # Callback for when an example fails.
    # Basically notifies the framework of the failure.
    def example_failed(notification)
      example = notification.example
      result = example.execution_result
      ex = result.exception
      @runner.update_result(Automation::Result::Fail)
      @runner.notify_test_failed(ex)
      Logging::Logger[example].error(format_exception(ex))
    end

  end

  # Wraps an RSpec test.
  class Test < Automation::Test::Test

    def initialize
      super
    end

    private

    # Overridden to configure RSpec prior to execution.
    def before_test
      super

      # Need local variables for access within the scoped blocks below.
      logger = @logger
      config_manager = @config_manager
      # Configure RSpec.
      RSpec.configure do |c|
        # Need access to framework methods from within the RSpec examples.
        c.include Automation::Kernel
        # The formatter that will feed RSpec notification to the framework.
        c.add_formatter(Automation::Rspec::Formatter)
        # Before each "it"
        c.before(:each) do
          @logger = logger
          @config_manager = config_manager
        end
      end
    end

    # Overridden to run the spec file using RSpec's runner.
    def test_script
      spec_directory = @config_manager['test_pack.spec_directory']
      spec_file = File.join(spec_directory, "#{@name}_spec.rb")
      @logger.info("Starting spec '#{spec_file}'...")
      RSpec::Core::Runner.run([spec_file])
    end

  end

end
