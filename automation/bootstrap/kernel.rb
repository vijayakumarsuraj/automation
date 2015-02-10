#
# Suraj Vijayakumar
# 13 Mar 2013
#

# Refinements for the Ruby Kernel.
module Automation

  # The automation kernel that is included into all Components.
  module Kernel

    # Flag to indicate if the calling thread should wait for a background worker to complete a piece of work.
    WAIT_FOR_RESULT = true
    # An array containing the letters a-z and A-Z. Used to generate random strings.
    LETTERS = [*('a'..'z'), *('A'..'Z')].flatten
    LETTERS_LENGTH = LETTERS.length

    # Adds an override property to the framework's config manager.
    #
    # @param [String] key
    # @param [Object] value
    def add_override_property(key, value, overrides = {})
      runtime.config_manager.add_override_property(key, value, overrides)
    end

    # Adds a standard property to the framework's config manager.
    #
    # @param [String] key
    # @param [Object] value
    def add_standard_property(key, value, overrides = {})
      runtime.config_manager.add_standard_property(key, value, overrides)
    end

    # Submits a job for execution.
    # If wait is true, the method will return the result of execution.
    # If wait is false, the method will return the task object.
    #
    # @param [Enumerable, Object] work an enumerable, each item is submitted to the thread pool.
    # @param [Boolean] wait if true, method will block, if false method will not block.
    # @param [Proc] job optional block if task is nil.
    # @return [Concurrent::Task] the task that has was scheduled.
    def background(work = nil, wait = false, overrides = {}, &job)
      thread_pool = runtime.thread_pool
      if work.kind_of?(Enumerable)
        tasks = work.map { |item| thread_pool.submit(nil, overrides, item, &job) }
        wait ? tasks.map { |task| task.result } : tasks
      else
        task = thread_pool.submit(nil, overrides, work, &job)
        wait ? task.result : task
      end
    end

    # Check to see if the specified file can be required without raising a file not found error.
    #
    # @param [String] file the file to check.
    # @return [Boolean] true if the file can be required, false otherwise.
    def can_require?(file)
      $LOAD_PATH.any? { |path| File.exist?(File.join(path, "#{file}.rb")) }
    end

    # Extends the specified target with the specified module.
    #
    # @param [Object] target the target to extend.
    # @param [Module] mod the module to extend with.
    def extend_with(target, mod)
      runtime.logger.trace("Extending '#{target}' with '#{mod}'")
      target.send(:extend, mod)
    end

    # Check if the specified feature is available.
    #
    # @param [String] feature
    # @return [Boolean]
    def feature_available?(feature)
      features_directory = runtime.config_manager['features_directory']
      feature_directory = File.join(features_directory, feature)
      File.exist?(feature_directory)
    end

    # Returns a formatted version of the specified exception.
    #
    # @param [Exception] ex the exception - defaults to $!.
    # @return [String] formatted string that represents the exception and its backtrace.
    def format_exception(ex = $!)
      ex_message = ["#{ex.message} (#{ex.class.name})"] + ex.backtrace
      ex_message.join("\n    from ")
    end

    # "Includes" all required extensions into the specified component.
    #
    # @param [Component] component the component to enhance.
    # @param [String] type the type of the component (mode, task, etc...).
    # @param [String] name the id of the component.
    # @return [Component] the enhanced component.
    def include_extensions(component, type, name)
      component_metaclass = metaclass(component)
      extensions = Component.get_extensions(type, name)
      extensions.each do |extension|
        runtime.logger.trace("Include '#{extension}' into #{type}.#{name}")
        component_metaclass.send(:include, extension)
      end
      # Return the component.
      component
    end

    # Includes the specified module only if it has not already been included!
    #
    # @param [Module] mod the module to include.
    def include_if_missing(mod)
      include(mod) unless included_modules.index(mod)
    end

    # Includes the specified module into the specified target.
    #
    # @param [Object] target the target to include into.
    # @param [Module] mod the module to include.
    def include_into(target, mod)
      runtime.logger.trace("Including '#{mod}' into '#{target}'...")
      target.send(:include, mod)
    end

    # Loads the specified component and includes all required extensions also.
    #
    # @param [String] type the type of the component (mode, task, etc...).
    # @param [String] name the id of the component.
    # @param [Array] args arguments to be passed to the component's constructor.
    # @return [Component] the object that represents the specified component.
    def load_component(type, name, *args, ** overrides)
      config_manager = runtime.config_manager
      application = config_manager['run.application']
      mode = config_manager['run.mode']
      require_file, class_name, singleton = Component.get_details(application, mode, type, name, overrides)
      # If the component is marked as a singleton and an instance of it has already been created, we return that
      # instance instead of loading a new one.
      if singleton && runtime.loaded_components.has_key?(class_name)
        return runtime.loaded_components[class_name]
      end
      # If the component is not marked as a singleton or it hasn't been instantiated before, we create an instance.
      runtime.logger.finer("Loading '#{class_name}' from '#{require_file}'...")
      require require_file
      component = constant(class_name).new(*args)
      component = include_extensions(component, type, name)
      component.component_name = name
      # If the singleton flag was true, we also save the instance for later use.
      runtime.loaded_components[class_name] = component if singleton
      # And return it.
      component
    end

    # Returns the metaclass for the specified object. If an object is not specified, uses self.
    def metaclass(object = self, &block)
      meta = class << object
        self
      end
      #
      block_given? ? meta.module_eval(&block) : meta
    end

    # Starts a new process, attaches to its stderr and stdout streams and waits till the process completes.
    # If a block is provided, each line from the stdout / stderr streams are yielded to the block.
    # Returns a status object.
    #
    # @param [Array] args arguments - see Open3.popen2e
    #   Additional options:
    #     track: if true, the process' id will be saved by the framework (for force killing later on).
    # @return [Process::Status] the status of the process.
    def popen(*args)
      opts = args[-1].kind_of?(Hash) ? args[-1] : {}
      track = opts.delete(:track)
      # Launch the required process and wait till it completes.
      # All output is yielded, line-by-line.
      Open3.popen2e(*args) do |_, stdout, thread|
        update_pid(thread.pid) if track
        while (line = stdout.readline)
          yield line if block_given?
        end rescue EOFError
        # Return the status
        thread.value
      end
    end

    # Starts a new process and returns the value of stdout and stderr.
    #
    # @param [String] executable the path to or the name of the executable.
    # @param [Array] args command line arguments.
    # @return [Array<String, Process::Status>] the status of the process.
    def popen_capture(executable, *args)
      Open3.capture2e(executable, *args)
    end

    # Returns a random letter.
    #
    # @return [String] a random letter.
    def random_letter
      LETTERS[rand(LETTERS_LENGTH)]
    end

    # Generates a random string with the specified length.
    #
    # @param [Integer] length the length of the required string.
    # @return [String] the random string.
    def random_string(length = 5)
      (0...length).map { random_letter }.join
    end

    # The automation environment.
    #
    # @return [Automation::Runtime]
    def runtime
      Runtime.instance
    end

    # Executes the provided block raising an error if it takes longer than sec seconds to complete.
    #
    # @param [Integer] secs
    def timeout(secs, &block)
      Timeout::timeout(secs, &block)
    end

  end

end

module Kernel

  # The platform constant.
  X_86 = 'x86'
  X_64 = 'x64'

  # Package definitions.
  PACKAGE_CLASS = {}

  # Defines a package.
  # Packages must call this method to register their package so that the framework can install / uninstall / package them.
  #
  # @param [String] name
  # @param [String] file
  # @param [Class] clazz
  def register_package(name, file, clazz)
    PACKAGE_CLASS[file] = clazz
    PACKAGE_CLASS[name] = clazz
  end

  # Returns the current platform.
  #
  # @return [Integer] X_64 or X_86.
  def ruby_platform
    RUBY_PLATFORM.start_with?('x64') ? X_64 : X_86
  end

  # Returns a list of super classes for the specified class.
  #
  # @param [Class] clazz the class to check.
  # @return [Array<Class>] list of super classes.
  def superclasses(clazz)
    parents = []
    current = clazz
    # Keep going till superclass returns a nil (i.e. Object)
    until (parent = current.superclass).nil?
      parents << parent
      current = parent
    end

    parents
  end

  # Executes the provided block silently (i.e. no warning messages are issued).
  #
  # @param [Proc] block the block to execute silently.
  def silently(&block)
    warn_level = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = warn_level
  end

end