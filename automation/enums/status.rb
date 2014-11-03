#
# Suraj Vijayakumar
# 10 May 2013
#

require 'automation/core/enum'

module Automation

  # Represent the status of a result.
  class Status < Enum

    # Indicates that a task is running.
    Running = create(0)
    # Indicates that a task's analysis is pending.
    Analysing = create(1)
    # Indicates that a task is complete.
    Complete = create(2)

  end

end
