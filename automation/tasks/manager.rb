#
# Suraj Vijayakumar
# 25 Feb 2014
#

require 'drb/drb'

require 'automation/core/component'
require 'automation/core/task'

require 'automation/support/runnable'

require 'automation/manager/controller'
require 'automation/manager/service'

module Automation

  # Provides an out of process DRb service that the framework can connect to.
  class Manager < Task

    # New manager.
    def initialize
      super

      @persist = false
    end

    # Stops the underlying DRb service.
    def stop
      @server.stop_service
      @controller.stop
      # Delete 'manager_uri' property. It's not needed anymore.
      @results_database.remove_run_property(@run_result, 'manager_uri')
    end

    private

    # The following steps are carried out (in no particular order):
    # 1. Starts the DRb server.
    def run
      drb_start
    end

    # Starts the underlying DRb server.
    def drb_start
      @run_result = @results_database.get_run_result
      @controller = Controller.new
      @controller.start_services

      @server = DRb.start_service(nil, @controller)
      @results_database.set_run_property(@run_result, 'manager_uri', @server.uri)

      @logger.debug("Process manager started : #{@server.uri}")
    end

  end

end
