#
# Suraj Vijayakumar
# 03 Mar 2014
#

require 'automation/core/component'
require 'automation/core/task'

module Automation

  class Manager < Task

    # Acts as the 'front' for all DRb calls.
    class Controller < Component

      # New controller.
      def initialize
        super

        @services = {}
      end

      def method_missing(method, *args, &block)
        # Find a service that can respond to this request.
        @services.each_pair do |_, value|
          return value.send(method, *args, &block) if value.respond_to?(method)
        end
        # No service has been registered to handle this request.
        super
      end

      # Starts all required services on this controller.
      #
      def start_services
        @config_manager.get_child?('manager.service').each_child do |config|
          next unless config['enabled']
          name = config.name
          service = load_component(Component::ServiceType, name)
          @services[name] = service
          @logger.info("Service '#{name}' successfully registered")
        end
      end

      private

    end

  end

end