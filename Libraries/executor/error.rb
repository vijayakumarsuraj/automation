#
# Suraj Vijayakumar
# 09 Aug 2013
#

require 'util/chained_error'

module Executor

  # General concurrency error.
  class ExecutorError < RuntimeError

    include Util::ChainedError

  end

  # Error raised by the task list.
  class TaskListError < ExecutorError
  end

end
