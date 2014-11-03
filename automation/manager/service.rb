#
# Suraj Vijayakumar
# 09 Apr 2014
#

require 'automation/core/component'
require 'automation/core/task'

module Automation

  class Manager < Task

    # Represents a service that can be registered on a controller.
    class Service < Component

      # New service.
      def initialize
        super

        @component_name = @component_name.snakecase
      end

      private

      # Gets the value of the specified service property.
      #
      # @param [String] key
      # @param [Hash] options
      def service_config(key, options = {})
        @config_manager["manager.service.#{@component_name}.#{key}", options]
      end

    end

  end

end