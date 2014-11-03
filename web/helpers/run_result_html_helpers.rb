#
# Suraj Vijayakumar
# 16 Jul 2013
#

module Automation

  module RunResultHtmlHelpers

    # Returns an html fragment for the run result's change status.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @return [Array] the HTML fragments (0 = the span elements; 1 = the hint scripts (also an array)).
    def run_result_status_change_html(run_result)
      run_name = run_result.run_name
      added, removed, failing, passing, changed = run_result_change_counts(run_result)
      pass_style = result_style(Automation::Result::Pass)
      fail_style = result_style(Automation::Result::Fail)
      spans = []
      # Build the spans.
      if added > 0
        id = "#{run_name}_added"
        hint = "#{added} #{pluralize(added, 'new %s added in this run.', 'test')}"
        spans << "<span id=\"#{id}\" title=\"#{hint}\">+#{added}</span>"
      end
      if removed > 0
        id = "#{run_name}_removed"
        hint = "#{removed} #{pluralize(removed, 'existing %s removed in this run.', 'test')}"
        spans << "<span id=\"#{id}\" title=\"#{hint}\">-#{removed}</span>"
      end
      if failing > 0
        id = "#{run_name}_failing"
        hint = "#{failing} #{pluralize(failing, 'new %s in this run.', 'failure')}"
        spans << "<span id=\"#{id}\" class=\"#{fail_style}\" title=\"#{hint}\">#{failing}</span>"
      end
      if passing > 0
        id = "#{run_name}_passing"
        hint = "#{passing} #{pluralize(passing, 'new %s in this run.', 'success')}"
        spans << "<span id=\"#{id}\" class=\"#{pass_style}\" title=\"#{hint}\">#{passing}</span>"
      end
      if changed > 0
        id = "#{run_name}_changed"
        hint = "#{changed} #{pluralize(changed, 'changed %s in this run.', 'failure')}"
        spans << "<span id=\"#{id}\" class=\"#{fail_style}\" title=\"#{hint}\">+#{changed}</span>"
      end
      # If there were no changes.
      if spans.length == 0
        spans << "<span class=\"#{pass_style}\">Nothing new here!</span>"
      end
      # The HTML fragments
      spans.join(' / ')
    end

    # Returns an html fragment for the run result's test count status.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @return [String] the HTML fragment.
    def run_result_status_test_count_html(run_result)
      pass, fail, ignored = @results_database.get_run_result_test_counts(run_result)
      total = pass + fail
      pass_style = result_style(Automation::Result::Pass)
      fail_style = result_style(Automation::Result::Fail)
      pass_hint = "#{pass} #{pluralize(pass, '%s passed in this run.', 'test')}"
      fail_hint = "#{fail} #{pluralize(fail, '%s failed in this run.', 'test')}"
      #
      pass_span = "<span class=\"#{pass_style}\" title=\"#{pass_hint}\">#{pass}</span>"
      fail_span = "<span class=\"#{fail_style}\" title=\"#{fail_hint}\">#{fail}</span>"

      "<span>Executed: #{total} (#{pass_span} / #{fail_span})</span>"
    end

    # Returns an html fragment for the run result's change summary.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result
    # @return [String] the HTML fragment.
    def run_result_summary_change_html(run_result)
      # Inner function to build the span for a change.
      #
      # @param [Integer] count the count.
      # @param [String] pattern the suffix pattern.
      # @param [Array] args additional substitution arguments.
      # @return [String] the html span.
      def span(count, pattern, *args)
        "<span><strong>#{count}</strong> #{pluralize(count, pattern, *args)}</span>"
      end

      added, removed, failing, passing, changed = run_result_change_counts(run_result)
      # Build the spans that need to be added.
      spans = []
      spans << span(added, '%s added', 'test') if added > 0
      spans << span(removed, '%s removed', 'test') if removed > 0
      spans << span(failing, 'new %s', 'failure') if failing > 0
      spans << span(passing, 'new %s', 'success') if passing > 0
      spans << span(changed, 'changed %s', 'failure') if changed > 0
      # Return html.
      spans.join(', ')
    end

    # Returns an html fragment for the run result's test counts.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result
    # @return [String] the HTML fragment.
    def run_result_summary_test_count_html(run_result)
      pass, fail, ignored = @results_database.get_run_result_test_counts(run_result)
      total = pass + fail
      pass_percentage = total > 0 ? '%.2f%' % (Float(pass) / Float(total) * 100.0) : 'NaN'
      pass_style = result_style(Automation::Result::Pass)
      fail_style = result_style(Automation::Result::Fail)
      #
      total_span = "<span><strong>#{total}</strong> #{'test'.pluralize(total)}</span>"
      fail_span = "<span class=\"#{fail_style}\"><strong>#{fail}</strong> failed</span>"
      pass_span = "<span class=\"#{pass_style}\"><strong>#{pass}</strong> passed</span>"
      pass_percentage_span = "<span><strong>#{pass_percentage}</strong></span>"

      "Out of #{total_span}, #{fail_span} and #{pass_span} (#{pass_percentage_span})"
    end

    private

  end

end
