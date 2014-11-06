#
# Suraj Vijayakumar
# 31 Oct 2014
#


require 'automation/console/console_command'

require 'automation/core/package'

module Automation

  class PackageCommand < ConsoleCommand

    # Package command.
    #
    # @param [Automation::Console] console the mode that executed this command.
    def initialize(console)
      super
    end

    # Executes the package command.
    def execute
      while true
        type = prompt('Type (application,test_pack,feature,exit): ')
        return if type.eql?('exit')
        # Get the prefix and class to use.
        method_name = "type_#{type}"
        next echo("Type '#{type}' not recognized - Method '#{method_name}' not found") unless respond_to?(method_name, true)
        prefix, plugin = send(method_name)
        # Execute action loop indefinitely.
        action_loop(prefix, plugin)
      end
    end

    private

    # Returns the class for working with 'application' packages.
    #
    # @return [Array<String, Automation::Package>]
    def type_application
      require 'automation/packages/application_package'
      ['Application', Automation::ApplicationPackage]
    end

    # Returns the class for working with 'feature' packages.
    #
    # @return [Array<String, Automation::Package>]
    def type_feature
      require 'automation/packages/feature_package'
      ['Feature', Automation::FeaturePackage]
    end

    # Returns the class for working with 'test_pack' packages.
    #
    # @return [Array<String, Automation::Package>]
    def type_test_pack
      require 'automation/packages/test_pack_package'
      ['Test pack', Automation::TestPackPackage]
    end

    # Loop indefinitely prompting for and executing actions.
    #
    # @param [String] prefix
    # @param [Class] clazz
    def action_loop(prefix, clazz)
      while true
        action = prompt("#{prefix} action (install,package,uninstall,exit): ")
        return if action.eql?('exit')

        method_name = "action_#{action}"
        next echo("Action '#{action}' not recognized - Method '#{method_name}' not found") unless respond_to?(method_name, true)
        send(method_name, prefix, clazz) rescue echo($!.message)
      end
    end

    # Executes the 'install' action.
    #
    # @param [String] prefix
    # @param [Class] clazz
    def action_install(prefix, clazz)
      file_path = prompt("#{prefix} zip path: ")
      plugin = clazz.new(file_path)
      app_name = plugin.install
      echo("#{prefix} installed - #{app_name}")
    end

    # Executes the 'package' action.
    #
    # @param [String] prefix
    # @param [Class] clazz
    def action_package(prefix, clazz)
      app_name = prompt("#{prefix} name : ")
      plugin = clazz.new("#{app_name}.zip")
      plugin_file = plugin.package(app_name)
      echo("Package created - #{plugin_file}")
    end

    # Executes the 'uninstall' action.
    #
    # @param [String] prefix
    # @param [Class] clazz
    def action_uninstall(prefix, clazz)
      app_name = prompt("#{prefix} name : ")
      clazz.uninstall(app_name)
      echo("#{prefix} uninstalled")
    end

  end

end
