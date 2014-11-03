#
# Suraj Vijayakumar
# 25 Feb 2014
#

require 'drb/drb'

require 'automation/manager/observer'

module Automation

  # The observer for test runner tasks.
  # Uses DRb to notify the 'TestMonitor' service when tests start and finish.
  class TestMonitorObserver < Automation::Manager::Observer

    private

    # Method for the message 'test_alive'.
    def test_alive(source, *args)
      @manager.test_heartbeat(@config_manager['test.name'])
    end

    # Method for the message 'test_started'.
    def test_started(source, *args)
      @manager.test_register(@config_manager['test.name'])
    end

    # Method for the message 'test_finished'.
    def test_finished(source, *args)
      @manager.test_unregister(@config_manager['test.name'])
    end

  end

end
