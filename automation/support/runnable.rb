#
# Suraj Vijayakumar
# 05 Dec 2012
#

module Automation

  # Provides the scaffolding required for a runnable task.
  module Runnable

    # Starts this runnable. This will call the setup, run and shutdown methods.
    # If there are any exceptions, the exception method is invoked.
    # Finally, the cleanup method is invoked.
    def start
      begin
        setup
        run
        shutdown
      rescue
        exception($!)
      rescue Interrupt
        interrupt($!)
      ensure
        cleanup
      end
    end

    private

    # Cleans up any resources for this runnable.
    # The default implementation does nothing.
    def cleanup
    end

    # Exception callback. Invoked only if an error is encountered. Implementations must provide this method.
    def exception(ex)
      raise NotImplementedError.new("Method 'exception' not implemented by '#{self.class.name}'")
    end

    # Interrupt callback. Default is to re-throw the error. 
    def interrupt(ex)
      raise ex
    end
    
    # Runs this runnable. Implementations must provide this method.
    def run
      raise NotImplementedError.new("Method 'run' not implemented by '#{self.class.name}'")
    end

    # Sets up this runnable.
    # The default implementation does nothing.
    def setup
    end

    # Shuts down this runnable.
    # The default implementation does nothing.
    def shutdown
    end

  end

end
