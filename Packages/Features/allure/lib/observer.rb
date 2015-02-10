#
# Suraj Vijayakumar
# 05 Mar 2013
#

require 'automation/manager/observer'

module Automation::Allure

  # The Allure observer.
  # Uses DRb to notify the 'Allure::Listener' service.
  class Observer < Automation::Manager::Observer

    private

    # Returns all required details for the specified test.
    #
    # @param [Array<String>] test suite_name, test_name.
    def _test_details(test)
      suite_name = test.category
      test_name = test.name
      test_description = test.description
      test_name_key = "[#{test_name}] #{test_description}"

      [suite_name, test_name_key]
    end

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
      suite_name, test_name = _test_details(test)

      @manager.allure_test_failed(test_name, exception)
    end

    # Method for the message 'test_finished'.
    def test_finished(source, *args)
      test = source.test
      suite_name, test_name = _test_details(test)

      @manager.allure_stop_test(suite_name, test_name)
    end

    # Method for the message 'test_screenshot'.
    def test_screenshot(source, file)
      test = source.test
      suite_name, test_name = _test_details(test)

      @manager.allure_add_attachment(suite_name, test_name, file: file)
    end

    # Method for the message 'test_started'.
    def test_started(source, *args)
      test = source.test
      suite_name, test_name = _test_details(test)

      metadata = test.metadata
      feature = metadata.fetch(:feature, nil)
      severity = metadata.fetch(:priority, :normal).to_sym

      @manager.allure_start_test(suite_name, test_name, {feature: feature, severity: severity})
    end

    # Method for the message 'test_step_screenshot'.
    def test_step_screenshot(source, step_name, file)
      test = source.test
      suite_name, test_name = _test_details(test)

      @manager.allure_add_attachment(suite_name, test_name, file, step: step_name, title: File.basename(file))
    end

    # Method for the message 'test_step_started'.
    def test_step_started(source, step_name, *args)
      test = source.test
      suite_name, test_name = _test_details(test)

      @manager.allure_start_step(suite_name, test_name, step_name)
    end

    # Method for the message 'test_step_finished'.
    def test_step_finished(source, step_name, status = :passed, *args)
      test = source.test
      suite_name, test_name = _test_details(test)

      @manager.allure_stop_step(suite_name, test_name, step_name, status)
    end

  end

end
