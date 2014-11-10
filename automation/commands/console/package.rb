#
# Suraj Vijayakumar
# 31 Oct 2014
#


require 'automation/console/console_command'

require 'automation/core/package'

module Automation

  class PackageCommand < ConsoleCommand

    # Maps types to their corresponding require files. Needed when 'un-installing' and 'packaging'
    REQUIRE_MAP = {'application' => '%{name}/package', 'feature' => '%{name}/package', 'test_pack' => 'Test Packs/%{name}/package'}

    # Package command.
    #
    # @param [Automation::Console] console the mode that executed this command.
    def initialize(console)
      super
    end

    # Executes the package command.
    def execute
      type = prompt('Type (application,test_pack,feature) : ')
      action = prompt('Action (install,package,uninstall)   : ')
      send("action_#{action}", type)
    rescue
      puts format_exception($!)
    end

    private

    # Executes the 'install' action. This is the same for all package types.
    def action_install(type)
      from = prompt('Install from : ')
      require "#{from}/package"
      plugin = Automation::PACKAGE_CLASS.new
      plugin.install(from)
      puts "Installed '#{type}' - #{plugin.name}"
    end

    # Executes the 'package' action. This is the same for all package types.
    def action_package(type)
      name = prompt('Name : ')
      dest = prompt('Destination : ')
      require REQUIRE_MAP[type] % {name: name}
      plugin = Automation::PACKAGE_CLASS.new
      plugin.package(dest)
      puts "Packaged '#{type}' - #{plugin.name}"
    end

    # Executes the 'package' action. This is the same for all package types.
    def action_uninstall(type)
      name = prompt('Name : ')
      require REQUIRE_MAP[type] % {name: name}
      plugin = Automation::PACKAGE_CLASS.new
      plugin.uninstall
      puts "Uninstalled '#{type}' - #{plugin.name}"
    end

  end

end
