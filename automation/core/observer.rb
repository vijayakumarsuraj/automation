#
# Suraj Vijayakumar
# 13 Dec 2012
#

require 'automation/core/component'

module Automation

  # Generic observer.
  class Observer < Component

    # New observer.
    def initialize
      super
      @throw_exception = false
      @component_type = Automation::Component::ObserverType
    end

    # Invoked when a task issues a change notification.
    #
    # @param [String] method the notification method.
    # @param [Task] source the source of the notification.
    # @param [Array] args any arguments that were passed with the notification.
    def update(method, source, *args)
      send(method, source, *args) if respond_to?(method, true)
    rescue
      raise if @throw_exception
      @logger.warn("Exception encountered - #{self.class.name}##{method}")
      @logger.debug(format_exception($!))
    end

  end

end
