#
# Suraj Vijayakumar
# 18 Jan 2013
#

require 'automation/core/task'

module Automation

  # Generic finaliser task.
  class Finaliser < Task

    private

    # The following steps are carried out by the default finaliser (in no particular order):
    # 1. Notify any listeners that this finaliser has finished.
    # 2. Update and save the run result entity.
    def cleanup
      if defined? @run_result
        @run_result.result = @result
        @run_result.save
      end
      #
      notify_change('finaliser_finished', @run_result)
      super
    end

    # The following steps are carried out by the default finaliser (in no particular order):
    # 1. Notify any listeners that this initialiser has failed.
    def exception(ex)
      notify_change('finaliser_failed')
      super
    end

    # The following steps are carried out by the default initialiser (in no particular order):
    def run
    end

    # The following steps are carried out by the default initialiser (in no particular order):
    # 1. Notify any listeners that this finaliser has started.
    def setup
      super
      notify_change('finaliser_started')
      #
      @run_result = @results_database.get_run_result
    end

  end

end

