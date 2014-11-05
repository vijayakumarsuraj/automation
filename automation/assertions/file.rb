#
# Suraj Vijayakumar
# 15 Apr 2013
#

require 'automation/core/assertion'

module Automation

  # An assertion for checking if the contents of two files are the same.
  class FileCompareAssertion < Assertion

    # New file compare assertion.
    #
    # @param [String] actual the path of the file with the actual output.
    # @param [String] expected the path of the file with the expected output.
    def initialize(actual, expected)
      super()

      @actual = actual
      @expected = expected
    end

    # Checks if the benchmark and output file match. Return true if they do, false otherwise.
    def check
      prefix = File.basename(@expected)
      if File.exist?(@expected)
        no_change = FileUtils.identical?(@expected, @actual)
        if no_change
          # Files are exact match.
          @message = "#{prefix} : Actual and expected files are an exact match."
          return true
        end
        @message = "#{prefix} : Actual file did not match expected file!"
      else
        @message = "#{prefix} : Expected file not found."
      end
      # Comparison failed.
      false
    end

  end

  # An assertion for checking if a file exists.
  class FileExistAssertion < Assertion

    # New file exists assertion.
    #
    # @param [String] file the path of the file to check.
    def initialize(file)
      super()

      @file = file
    end

    # Checks if the file exists.
    def check
      prefix = File.basename(@file)
      if File.exist?(@file)
        @message = "#{prefix} : Expected file exists"
        true
      else
        @message = "#{prefix} : Expected file not found."
        false
      end
    end

  end

  module Assertions

    private

    # Assertion for asserting that two files match exactly.
    #
    # @param [String] actual the path of the file with the actual output.
    # @param [String] expected the path of the file with the expected output.
    # @return [Automation::FileCompareAssertion] the file compare assertion.
    def files_match(actual, expected)
      FileCompareAssertion.new(actual, expected)
    end

    # Assertion for checking if a file exists.
    #
    # @param [String] file the path of the file to check.
    # @return [Automation::FileExistAssertion] the file exists assertion.
    def file_exist(file)
      FileExistAssertion.new(file)
    end

  end

end
