#
# Suraj Vijayakumar
# 25 May 2013
#

require 'automation/core/component'

module Automation

  class Command < Component

    # New command.
    #
    # @param [Automation::Component] parent the mode that executed this command.
    def initialize(parent)
      super()

      @parent = parent
      @component_type = Automation::Component::CommandType
    end

    # Executes this command. Implementations must be provided by sub-classes.
    def execute
      raise NotImplementedError.new("Method 'execute' not implemented by '#{self.class.name}'")
    end

  end

end