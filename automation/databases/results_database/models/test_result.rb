#
# Suraj Vijayakumar
# 22 Mar 2013
#

require 'automation/databases/results_database'

module Automation

  class ResultsDatabase < Database

    # Represents the results of a test in a run.
    class TestResult < BaseModel

      # Each test result is associated with a run.
      belongs_to :run_result, inverse_of: :test_results
      # Each test result is associated with a test whose results it represents.
      belongs_to :test, inverse_of: :test_results, class_name: 'Automation::ResultsDatabase::Test'

      # The properties hash.
      serialize :properties, Hash

      # Sets up default values.
      after_initialize :default_values
      def default_values
        self.result ||= Automation::Result::Unknown
        self.status ||= Automation::Status::Running
        self.end_date_time ||= nil
        self.properties ||= {}
      end

      # Custom accessors.
      include Automation::ResultAccessor
      include Automation::StatusAccessor

      # Invalidates this test result.
      def invalidate
        self.result = Automation::Result::Ignored
        self.save
      end

    end

  end

end
