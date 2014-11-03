#
# Suraj Vijayakumar
# 09 Aug 2013
#

module Executor

  # The event listener for task events.
  module TaskObserver

    # Callback invoked when an observed task changes.
    def task_changed(task, property)
      case property
        when 'ready'
          on_task_ready(task)
        when 'complete'
          on_task_complete(task)
        else
      end
    end

    private

    # Callback invoked when an observed task is ready for execution (i.e. all dependencies are satisfied).
    #
    # @param [Executor::Task] task the task that changed.
    def on_task_ready(task)
    end

    # Callback invoked when an observed task completes.
    #
    # @param [Executor::Task] task the task that changed.
    def on_task_complete(task)
    end

  end

end