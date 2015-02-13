#
# Suraj Vijayakumar
# 11 Nov 2014
#

require 'allure/report'

module Automation::Allure

  # Provides methods for accessing and working with the Allure.
  module Helpers

    # Alias chain when included.
    def self.included(target)
      target.send(:alias_method_chain, :run_result_header_links, :allure)
    end

    # Generates a report off of the results in the specified directory.
    # Allure reports will look the best when there is one file per test suite.
    # If specified directory contains more than one file per test suite, they will be merged.
    #
    # The report is also generated into this directory.
    #
    # @param [String] output_directory
    def allure_generate_report(output_directory)
      Automation::Allure::Report.merge(output_directory)
      output, status = Automation::Allure::Report.generate(output_directory, @config_manager['tool.allure.executable'])
      @logger.fine("Allure messages\n#{output}")
      raise Automation::ExecutionError.new('Allure encountered errors.') unless status.success?
    end

    # Overridden to add the 'allure' link if required.
    def run_result_header_links_with_allure(run_result)
      header_links = run_result_header_links_without_allure(run_result)
      allure_settings = @results_database.get_run_property_yaml(run_result, 'allure', {})
      if allure_settings[:show_report]
        header_links['allure.html'] = {display: 'Allure', href: link('run', run_result.run_name, 'allure.html')}
      end
      header_links
    end

  end

end
