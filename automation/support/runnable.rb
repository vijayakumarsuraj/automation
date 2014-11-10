#
# Suraj Vijayakumar
# 05 Dec 2012
#

module Automation

  # Provides the scaffolding required for a runnable task.
  module Runnable

    # Allows ability to report changes to any registered observers.
    include Observable

    # The result of executing this runnable - initially set to unknown.
    attr_reader :result

    # Notifies a change to all registered observers.
    #
    # @param [Array] args the arguments to pass to the registered observers.
    def notify_change(method, *args)
      changed
      notify_observers(method, self, *args)
    end

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

    # Updates the result of this task. Results can only go from less severe to more severe.
    #
    # @param [Result] new_result the new result.
    def update_result(new_result)
      @result = new_result if new_result > @result
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

    # Loads all observers for this runnable.
    def load_observers(prefix, observers = [])
      # Observers to be enabled for all tasks.
      run_observers = @config_manager.get_child?("#{prefix}.observers")
      run_observers = run_observers ? run_observers.map_child { |child| [child.name, child.value] } : []
      # Observers to be enabled for this task.
      component_observers = @config_manager.get_child?("#{prefix}.#{@component_name}.observers")
      component_observers = component_observers ? component_observers.map_child { |child| [child.name, child.value] } : []
      # Combined list of all observers.
      all_observers = Hash.new { |h, k| h[k] = true }
      (run_observers + component_observers + observers).each { |name, value| all_observers[name] = (all_observers[name] && value) }
      # Load up each observer that was enabled.
      all_observers.each_pair do |name, value|
        if value
          begin
            add_observer(load_component(Component::ObserverType, name))
          rescue
            @logger.warn("Observer '#{name}' failed to start.")
            @logger.debug(format_exception($!))
          end
        end
      end
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
