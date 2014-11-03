#
# Suraj Vijayakumar
# 13 Dec 2012
#

module Automation

  # The base class for all automation components. Provides the basic functionality required to operate
  # within the framework.
  class Component

    # Constants indicating the types of various components.
    CommandType = 'command'
    CoreType = 'core'
    DatabaseType = 'database'
    ModeType = 'mode'
    ObserverType = 'observer'
    ResultDataType = 'result_data'
    ServiceType = 'service'
    TaskType = 'task'
    TestType = 'test'

    # The Automation kernel.
    include Automation::Kernel

    # Get the file name and class name that should be loaded for the specified component.
    #
    # @param [String] application the name of the current application.
    # @param [String] mode the name of the current mode.
    # @param [String] type the type of the component (report, mode, task, etc...)
    # @param [String] component the name of the component.
    # @return [Array<String, Boolean>] the component's file, class name and singleton flag (true if singleton, false otherwise).
    def self.get_details(application, mode, type, component, overrides = {})
      config_manager = Automation.environment.config_manager
      # The component can specify an 'is_a' override - which basically means that the framework should look for and
      # load the specified override.
      parts = config_manager["#{type}.#{component}.is_a", default: component].split('.')
      name = parts[-1]
      application = parts[-2] unless parts[-2].nil?
      # Merge overrides with defaults.
      defaults = {class_name: config_manager["#{type}.#{name}.class_name", default: name.camelcase(:upper)],
                  singleton: config_manager["#{type}.#{name}.singleton", default: false],
                  require_file: config_manager["#{type}.#{name}.require_file", default: false]}
      overrides = defaults.merge(overrides)
      # Calculate require_path and class_name.
      application_camelcase = application.camelcase(:upper)
      type_plural = type.pluralize
      class_name = overrides[:class_name]
      singleton = overrides[:singleton]
      # The file containing this component can be in one of the following locations
      # 1. The configuration property <type>.<name>.require_file
      require_file_prop = overrides[:require_file]
      # 2. applications/<application>/<type_plural>/<mode>/<name>
      require_file_app_mode = "#{application}/#{type_plural}/#{mode}/#{name}"
      # 3. applications/<application>/<type_plural>/<name>
      require_file_app = "#{application}/#{type_plural}/#{name}"
      # 4. automation/<type_plural>/<mode>/<name>
      require_file_default_mode = "automation/#{type_plural}/#{mode}/#{name}"
      # 5. automation/<type_plural>/<name>
      require_file_default = "automation/#{type_plural}/#{name}"
      # Raise an error if it is not found in these locations.
      if require_file_prop
        require_file = require_file_prop
        class_name = "Automation::#{class_name}"
      elsif can_require?(require_file_app_mode)
        require_file = require_file_app_mode
        class_name = "Automation::#{application_camelcase}::#{class_name}"
      elsif can_require?(require_file_app)
        require_file = require_file_app
        class_name = "Automation::#{application_camelcase}::#{class_name}"
      elsif can_require?(require_file_default_mode)
        require_file = require_file_default_mode
        class_name = "Automation::#{class_name}"
      elsif can_require?(require_file_default)
        require_file = require_file_default
        class_name = "Automation::#{class_name}"
      else
        raise "Component '#{component}' - definition '#{type}.#{name}' not found"
      end
      # Return file and class name.
      [require_file, class_name, singleton]
    end

    # Get the extension modules for the specified type.
    #
    # @param [String] type the type (report, task, mode, etc...)
    # @param [String] name the name of the component
    # @return [Array<Module>] the list of modules that should be loaded.
    def self.get_extensions(type, name)
      config_manager = Automation.environment.config_manager
      application = config_manager['run.application']
      current_mode = config_manager['run.mode']
      # The name to use for loading extensions.
      parts = config_manager["#{type}.#{name}.is_a", default: name].split('.')
      name = parts[-1]
      #
      application_camelcase = application.camelcase(:upper)
      type_extension = "#{type}_methods"
      name_extension = "#{name}_methods"
      extension_modules = []
      # The following set of extensions are injected, if they exist.
      # 1. applications/<application>/support/<type_extension>
      require_file_app_type = "#{application}/support/#{type_extension}"
      if can_require?(require_file_app_type)
        require require_file_app_type
        type_extension_module_name = type_extension.camelcase(:upper)
        extension_modules << "Automation::#{application_camelcase}::#{type_extension_module_name}"
      end
      # 2. applications/<application>/support/<name_extension>
      require_file_app_name = "#{application}/support/#{name_extension}"
      if can_require?(require_file_app_name)
        require require_file_app_name
        name_extension_module_name = name_extension.camelcase(:upper)
        extension_modules << "Automation::#{application_camelcase}::#{name_extension_module_name}"
      end
      modes = Mode.mode_names(application, current_mode)
      modes.each do |mode|
        # 3. applications/<application>/support/<mode>/<type_extension>
        require_file_app_mode_type = "#{application}/support/#{mode}/#{type_extension}"
        if can_require?(require_file_app_mode_type)
          require require_file_app_mode_type
          type_extension_module_name = "#{mode}_#{type_extension}".camelcase(:upper)
          extension_modules << "Automation::#{application_camelcase}::#{type_extension_module_name}"
        end
        # 4. applications/<application>/support/<mode>/<name_extension>
        require_file_app_mode_name = "#{application}/support/#{mode}/#{name_extension}"
        if can_require?(require_file_app_mode_name)
          require require_file_app_mode_name
          name_extension_module_name = "#{mode}_#{name_extension}".camelcase(:upper)
          extension_modules << "Automation::#{application_camelcase}::#{name_extension_module_name}"
        end
      end
      # A list of modules is returned.
      extension_modules.map { |name| constant(name) }
    end

    # Gets the name of this component.
    attr_accessor :component_name
    # Gets the type of this component.
    attr_reader :component_type

    # New automation component.
    def initialize
      @config_manager = environment.config_manager
      @thread_pool = environment.thread_pool
      @logger = Logging::Logger[self]

      @component_name = self.class.basename
    end

  end

end
