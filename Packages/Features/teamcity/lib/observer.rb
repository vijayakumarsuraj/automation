#
# Suraj Vijayakumar
# 05 Mar 2013
#

require 'automation/core/observer'

module Automation

  # The TeamCity observer.
  class TeamcityObserver < Observer

    # New TeamCity observer.
    def initialize
      super

      @console = $stdout
    end

    private

    ESCAPE_REGEX = /('|\||\[|\])/
    TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%S.%L%z'

    # Adds escape characters so that team city understands the service message.
    def _escape_text(raw_text)
      if raw_text.kind_of?(Array)
        raw_text.map { |line| _escape_text(line) }.join('|n')
      else
        raw_text.gsub(ESCAPE_REGEX, '|\1').gsub("\n", '|n')
      end
    end

    # Get the timestamp in a format that TeamCity can understand.
    def _timestamp
      DateTime.now.strftime(TIMESTAMP_FORMAT)
    end

    # Method for the message 'finaliser_finished'.
    def finaliser_finished(source, run_result, *args)
      config_name = @config_manager['run.config_name']
      @console.puts("##teamcity[testSuiteFinished timestamp='#{_timestamp}' name='#{config_name}']")

      unless run_result.nil?
        results_database = environment.databases.results_database
        passed, failed, ignored = results_database.get_run_result_test_counts(run_result)
        @console.puts("##teamcity[buildStatus text='Tests failed: #{failed}, passed: #{passed}, ignored: #{ignored}']")
      end
    end

    # Method for the message 'runner_started'.
    def runner_started(source, *args)
      config_name = @config_manager['run.config_name']
      run_name = @config_manager['run.name']
      @console.puts("##teamcity[testSuiteStarted timestamp='#{_timestamp}' name='#{config_name}']")
      @console.puts("##teamcity[setParameter name='run.name' value='#{run_name}']")
      @console.puts("##teamcity[buildNumber '#{run_name}']")

      # Generate the 'results.html' file now.
      html = @config_manager['teamcity.artifact.results.html', default: nil]
      unless html.nil?
        file_name = @config_manager['teamcity.artifact.results.file_name']
        directory = @config_manager['run.working.directory']
        file = File.join(directory, file_name)
        File.write(file, html)
        @console.puts("##teamcity[publishArtifacts '#{file}']")
      end
    end

    # Method for the message 'test_failed'.
    def test_failed(source, assertion, *args)
      message = _escape_text(assertion.message)
      backtrace = _escape_text(assertion.backtrace.join("\n"))
      test_name = source.test.name
      @console.puts("##teamcity[testFailed flowId='#{test_name}' timestamp='#{_timestamp}' name='#{test_name}' message='#{message}' details='#{details}']")
    end

    # Method for the message 'test_finished'.
    def test_finished(source, *args)
      test_name = source.test.name
      @console.puts("##teamcity[testFinished flowId='#{test_name}' timestamp='#{_timestamp}' name='#{test_name}']")
    end

    # Method for the message 'test_started'.
    def test_started(source, *args)
      test_name = source.test.name
      @console.puts("##teamcity[testStarted flowId='#{test_name}' timestamp='#{_timestamp}' name='#{test_name}']")
    end

  end

end
