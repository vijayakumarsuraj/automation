#
# Suraj Vijayakumar
# 29 Dec 2012
#

require 'automation/core/component'

module Automation

  # Assertions supported by the 'assert' method.
  # Each assertion will add methods to this module which are then made available to all tests.
  module Assertions
  end

  # The base class for a test.
  class Test < Component

    # Include the assertions supported for this test.
    include Automation::Assertions

    # The name of this test.
    attr_accessor :name

    # The logger used by this test - initialised to point to the logger used by the TestRunner task.
    attr_writer :logger
    # The test runner that is executing this test.
    attr_writer :runner
    # The result data store for this test.
    attr_writer :result_data

    # A short description of this test. Default is an empty string.
    attr_reader :description
    # The category this test belongs to. Default is the config name.
    attr_reader :category
    # Arbitrary meta data for a test. Default is an empty hash.
    attr_reader :metadata

    # New test.
    def initialize
      super

      @component_type = Automation::Component::TestType

      @description = ''
      @category = 'default'
      @metadata = {}

      @runner = nil # Initialised automatically by the test runner.
      @result_data = nil # Initialised automatically by the test runner.
      @excel_data = nil # Initialised automatically when needed.
      @name = nil # Initialised automatically by the test pack.
    end

    # Starts the test.
    def start
      begin
        before_test
        test_script
        after_test
      rescue
        test_exception($!)
      ensure
        clean_test rescue @logger.warn(format_exception($!))
      end
    end

    # The type of this test. The default raises an exception to indicate that the test type has not been defined.
    def test_type
      raise NotImplementedError.new("Test type not defined by '#{self.class.name}'!") unless defined? @test_type
      @test_type
    end

    private

    # Executed after the #test_script method.
    def after_test
    end

    # Executed before the #test_script method.
    def before_test
    end

    # Executed after the #after_test method.
    def clean_test
    end

    # Asserts the specified assertion. If the assertion fails, the test is marked as failed.
    #
    # @param [Automation::Assertion] assertion the assertion.
    # @return [Boolean] true if the assertion succeeds, false otherwise.
    def assert(assertion)
      if assertion.check
        @logger.info("#{assertion.class.basename} passed -- #{assertion.message}")
        true
      else
        @runner.update_result(Automation::Result::Fail)
        @runner.notify_test_failed(assertion)
        @logger.error("#{assertion.class.basename} failed -- #{assertion.message}")
        false
      end
    end

    # Get the excel data object. Creates it if required.
    # Requires the 'excel' feature to be installed.
    def excel_data
      if @excel_data.nil?
        require 'excel/excel_data'
        @excel_data = Automation::ExcelData.new
      end

      @excel_data
    end

    # Get the data identified by the specified header and variable.
    # If the data does not exist, an error is raised.
    def get_data(header, variable)
      header = header.to_sym if header.instance_of?(String)
      variable = variable.to_sym if variable.instance_of?(String)

      excel_data[header][variable].data
    end

    # Loads input data from the specified input file (requires the 'excel' feature).
    # If the required flag is true (default) an exception is raised if the file is not found.
    def load_input_data(file, required = true, strip_blanks = true)
      # Update the excel data instance.
      excel_data.strip_blanks = strip_blanks
      # Load the file if it exists.
      file_path = File.expand_path(file)
      if File.exist?(file_path)
        @logger.fine("Loading data from '#{file_path}'...")
        excel_data.load_from_file(file_path)
      elsif required
        # File does not exist but file was marked as required. Raise an exception.
        raise DataError.new("Data file '#{file_path}' does not exist!")
      else
        # Optional, so ignore.
      end
    end

    # Get the process ID for this test.
    def pid
      @runner.pid
    end

    # Updates the data identified by the specified header and variable.
    # If the header / variable do not exist, new ones are created.
    def set_data(header, variable, new_data)
      header = header.to_sym if header.instance_of?(String)
      variable = variable.to_sym if variable.instance_of?(String)

      if excel_data.has_header?(header)
        header_object = excel_data[header]
        if header_object.has_variable?(variable)
          # The header and the variable exist, so just update the value.
          variable_object = header_object[variable]
        else
          # The header exists, but the variable doesn't - so create a new variable.
          variable_object = header_object.add_variable(variable)
        end
      else
        # The header (and therefore the variable) does not exist. So create both.
        header_object = excel_data.add_header(header)
        variable_object = header_object.add_variable(variable)
      end

      variable_object.data = new_data
    end

    # Invoked in case there was an exception executing a test. The default behaviour re-raises the exception.
    def test_exception(ex)
      @runner.update_result(Automation::Result::Exception)

      raise(ex)
    end

    # This test's methods. Implementations *must* provide this method.
    def test_script
      raise NotImplementedError.new("Method 'test_script' not implemented by '#{self.class.name}'")
    end

    # Updates the process ID of this test (for tests that launch another process).
    #
    # @param [String, Integer] pid the PID.
    def update_pid(pid)
      @runner.update_pid(pid)
    end

  end

end