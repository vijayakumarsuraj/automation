#
# Suraj Vijayakumar
# 09 Apr 2014
#

require 'drb/drb'

require 'automation/core/observer'
require 'automation/core/task'

module Automation

  class Manager < Task

    # Represents an observer that will connect to the manager using DRb.
    class Observer < Automation::Observer

      # New observer.
      def initialize
        super

        results_database = runtime.databases.results_database
        run_result = results_database.get_run_result
        uri = results_database.get_run_property(run_result, 'manager_uri')
        raise 'Could not determine manager URI' if uri.nil?

        @manager = DRbObject.new_with_uri(uri)
        @logger.debug("Connected to process manager : #{uri}")
      end

      # Overridden to ignore all calls if a connection to the manager was not made.
      def update(method, source, *args)
        super unless @manager.nil?
      end

    end

  end

end