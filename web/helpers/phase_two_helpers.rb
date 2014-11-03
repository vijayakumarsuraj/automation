#
# Suraj Vijayakumar
# 02 Dec 2013
#

module Automation

  # Provides methods for accessing and working with the PhaseTwo database.
  module PhaseTwoHelpers

    # Performs initializations that are specific to the reval pages.
    def phase_two_before
      return unless @path_info.start_with?('/phase_two/')

      @header[:styles] << 'phase_two.css'
      @phase_two_database = @databases['phase_two']
    end

    # Formats the specified number.
    #
    # @param [Float, Integer] number
    # @return [String]
    def phase_two_format_number(number)
      return '-' if number.nil?
      Automation::Converter.to_number_with_delimiter('%.2f' % number, ',')
    end

    # Get the previous task for the specified task result.
    #
    # @param [Automation::ResultsDatabase::TaskResult] task_result
    # @return [Automation::ResultsDatabase::TaskResult]
    def phase_two_previous_task_result(task_result)
      version = task_result.properties['binaries.version']
      previous_run_result = @results_database.get_analysed_against_run_result(task_result.run_result)
      previous_task_ids = @results_database.get_run_property_yaml(previous_run_result, "tasks.#{version}")
      previous_task_result = @results_database.find_task_result(previous_task_ids[task_result.task.task_name])
    end

    # Get the PhaseTwo task result for the specified version.
    def phase_two_task_result(version, run_result)
      @results_database.get_task_results(run_result, 'phase_two_runner').each do |tr|
        return tr if tr.properties['binaries.version'].eql?(version)
      end
      # No match, return nil.
      nil
    end

  end

end
