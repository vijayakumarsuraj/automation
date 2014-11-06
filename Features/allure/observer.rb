#
# Suraj Vijayakumar
# 05 Mar 2013
#

require 'automation/manager/observer'

module Automation

  # The Allure observer.
  # Uses DRb to notify the 'AllureListener' service.
  class AllureObserver < Automation::Manager::Observer

    private

    # Method for the message 'finaliser_finished'.
    def finaliser_finished(source, *args)
      @manager.allure_stop
    end

    # Method for the message 'runner_started'.
    def runner_started(source, *args)
      @manager.allure_start
    end

    # Method for the message 'test_failed'.
    def test_failed(source, exception, *args)
      test = source.test
      suite_name = test.category
      test_name = test.name
      test_description = test.description

      test_name_key = "[#{test_name}] #{test_description}"
      @manager.allure_test_failed(test_name_key, exception)
    end

    # Method for the message 'test_finished'.
    def test_finished(source, *args)
      test = source.test
      suite_name = test.category
      test_name = test.name
      test_description = test.description

      test_name_key = "[#{test_name}] #{test_description}"
      @manager.allure_stop_test(suite_name, test_name_key)
    end

    # Method for the message 'test_started'.
    def test_started(source, *args)
      test = source.test
      suite_name = test.category
      test_name = test.name
      test_description = test.description

      metadata = test.metadata
      feature = metadata[:feature]
      severity = metadata[:priority].to_sym

      test_name_key = "[#{test_name}] #{test_description}"
      @manager.allure_start_test(suite_name, test_name_key, {feature: feature, severity: severity})
    end

    # Method for the message 'test_step_started'.
    def test_step_started(source, step_name, *args)
      test = source.test
      suite_name = test.category
      test_name = test.name
      test_description = test.description

      test_name_key = "[#{test_name}] #{test_description}"
      @manager.allure_start_step(suite_name, test_name_key, step_name)
    end

    # Method for the message 'test_step_finished'.
    def test_step_finished(source, step_name, status = :passed, *args)
      test = source.test
      suite_name = test.category
      test_name = test.name
      test_description = test.description

      test_name_key = "[#{test_name}] #{test_description}"
      @manager.allure_stop_step(suite_name, test_name_key, step_name, status)
    end

  end

end
