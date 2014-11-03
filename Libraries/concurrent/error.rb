#
# Suraj Vijayakumar
# 09 Mar 2013
#

require 'util/chained_error'

module Concurrent

  # General concurrency error.
  class ConcurrencyError < RuntimeError

    include Util::ChainedError

  end

  # Runtime error raised by a task.
  class TaskRuntimeError < ConcurrencyError
  end

  # Raised by a ThreadPool to indicate to running tasks that they should stop running immediately.
  class ThreadPoolShutdownNow < Exception
  end

end
