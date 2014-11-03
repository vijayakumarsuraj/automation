#
# Suraj Vijayakumar
# 08 Mar 2013
#

require 'thread'
require 'logging'

require 'concurrent/task'
require 'concurrent/error'

# Monkey patched to include an 'insert' method.
class Queue

  # Deletes the specified objects from this thread pool.
  #
  # @param [Array<Object>] objs the objects to delete.
  # @return [Array<Object>] the list of objects that were actually deleted.
  def delete(*objs)
    deleted = []
    @mutex.synchronize do
      objs.each do |obj|
        deleted << @que.delete(obj) if @que.include?(obj)
      end
    end
    deleted
  end

  # Inserts an object into the queue.
  #
  # @param [Integer] index the index to insert at.
  # @param [Object] obj the object to insert.
  def insert(index, obj)
    @mutex.synchronize do
      @que.insert(index, obj)
      begin
        t = @waiting.shift
        t.wakeup if t
      rescue ThreadError
        retry
      end
    end
  end

end

module Concurrent

  class ThreadPool

    # New thread pool with the specified number of threads.
    #
    # @param [Integer] size the number of threads to maintain.
    # @param [String] name the name of the thread pool (default is 'ThreadPool').
    # @param [String] ndc the prefix for the nested diagnostic context for the threads of this thread pool.
    def initialize(size, name = 'ThreadPool', ndc = 'thread')
      @size = size

      @mutex = Mutex.new
      @queue = Queue.new
      @token = ConditionVariable.new
      @shutdown = false
      @logger = Logging::Logger[name]

      @threads = []
      @size.times do |i|
        @threads << Thread.new do
          Logging.ndc.clear
          Logging.ndc.push("#{ndc}-#{i + 1}")
          execute_tasks
          Logging.ndc.pop
        end
      end
    end

    # Deletes all the specified tasks from this thread pool.
    #
    # @param [Array<Task>] tasks the tasks to delete.
    # @return [Array<Task>] the list of tasks that were actually deleted.
    def delete(*tasks)
      @queue.delete(*tasks)
    end

    # Instructs this thread pool to shutdown after all executing and queued tasks are complete.
    # No new tasks are accepted.
    def shutdown
      synchronize do
        @shutdown = true
        @token.broadcast
      end
    end

    # Kills all threads immediately and shuts down this thread pool.
    # All queued tasks will throw exceptions.
    def shutdown_now
      synchronize { @shutdown = true }
      @threads.each { |thread| thread.raise(Concurrent::ThreadPoolShutdownNow.new) }
      synchronize { @token.broadcast }
      # Empty the task queue raising an exception in each task.
      begin
        @queue.pop(true).raise_error(Concurrent::ThreadPoolShutdownNow.new) while true
      rescue ThreadError
        # Ignore and return.
      end
    end

    # Submits a job for execution. The method does not block and returns immediately with a Task object.
    # If task is provided, it is scheduled directly. If a block is provided, it is wrapped within a Task and
    # then scheduled.
    # @param [Task] task The task to execute. If nil a task is created with the specified arguments and block.
    # @param [Hash] overrides Optional overrides to control how the task is submitted.
    #   first: True if this task will be queued as the first task (default is false).
    # @param [Task] args The arguments to be provided to the task (used only if task is nil).
    # @param [Proc] job The actual work to be done by the task (used only if task is nil).
    # @return [Concurrent::Task] the task that has was scheduled.
    def submit(task, overrides = {}, *args, &job)
      defaults = {first: false}
      overrides = defaults.merge(overrides)
      #
      raise ArgumentError.new('Cannot submit - Either a block or a task is allowed') if !task.nil? && block_given?
      raise ArgumentError.new('Cannot submit - Either a block or a task is required') if task.nil? && !block_given?
      task = Concurrent::Task.new(*args, &job) if task.nil?
      # Try to submit the task. Return the task if we succeed.
      synchronize do
        raise Concurrent::ConcurrencyError.new('Cannot submit - ThreadPool is shutting down or has shut down') if @shutdown
        # Queue the task. It will be executed when a thread becomes free.
        task.queued
        overrides[:first] ? @queue.insert(0, task) : @queue.push(task)
        @token.signal # If any threads are idle, wake one up to run this task.
      end
      #
      task
    end

    # Executes the specified block using this thread pool's mutex.
    def synchronize(&block)
      @mutex.synchronize(&block)
    end

    # Waits for all the threads of this thread pool to stop.
    #
    # @param [Integer] timeout the maximum number of seconds to wait for each thread to stop.
    def wait_for(timeout = 5)
      @threads.each { |thread| timeout > 0 ? thread.join(timeout) : thread.join }
    end

    private

    # Indefinitely process tasks from this thread pool's queue. This method will return only after the thread pool
    # has been shut down and all available tasks have been processed.
    def execute_tasks
      while true
        task = synchronize { get_task }
        task.execute
      end
    rescue Concurrent::ThreadPoolShutdownNow
      # ignored
    end

    # Get the next available task in this thread pool. Waits till a task becomes available.
    # Returns nil if the ThreadPool is shutting down.
    #
    # @return [Concurrent::Task] the next available task.
    def get_task
      @queue.pop(true)
    rescue ThreadError
      # No tasks are available right now.
      # If the ThreadPool has been told to shutdown, raise an exception (so that we stop working).
      raise Concurrent::ThreadPoolShutdownNow.new if @shutdown
      # Otherwise wait for a task to become available and retry.
      @token.wait(@mutex)
      retry
    end

  end

end