#
# Suraj Vijayakumar
# 25 Feb 2014
#

require 'automation/manager/observer'

module Automation::Test

  # The observer for test runner tasks.
  # Uses DRb to notify the 'TestMonitor' service when tests start and finish.
  class TestMonitorObserver < Automation::Manager::Observer

    private

    # Method for the message 'test_alive'.
    def test_alive(source, *args)
      @manager.test_monitor_heartbeat(source.test.name)
    end

    # Method for the message 'test_started'.
    def test_started(source, *args)
      @manager.test_monitor_register(source.test.name)
    end

    # Method for the message 'test_finished'.
    def test_finished(source, *args)
      @manager.test_monitor_unregister(source.test.name)
    end

  end

end
