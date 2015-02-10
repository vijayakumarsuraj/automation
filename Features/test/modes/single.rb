#
# Suraj Vijayakumar
# 19 Jan 2015
#

require 'automation/modes/single'

module Automation

  # Overrides for when the 'test' feature is enabled.
  class Single < Mode

    private

    # Overridden to return the name of the test when the task is 'test_runner'. Otherwise use the default behaviour.
    def log_file_name
      @task_id == 'test_runner' ? "#{@test_name}" : @task_id
    end

  end

end
