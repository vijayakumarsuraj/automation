#
# Suraj Vijayakumar
# 19 Nov 2013
#

require 'configuration/nodes/property_node'

module Configuration

  # A simple node that can store a value.
  class GeneratedPropertyNode < PropertyNode

    # The generator block for this property.
    attr_reader :generator

    # Creates a new property with the specified
    #
    # @param [String] name the name of the property.
    # @param [Proc] generator the generator proc to call when the property's value needs to be generated.
    def initialize(name, &generator)
      super(name, nil)

      @generator = generator
    end

    # Overridden to create a duplicate of this GeneratedPropertyNode.
    def dup
      GeneratedPropertyNode.new(@name, &@generator)
    end

    # Get the value of this property.
    #
    # @param [Hash] overrides overrides to apply while evaluating the property's value.
    # :interpolate - true if the value should be interpolated, false to return the raw value.
    # :context - the global context to use when interpolating references.
    # :parameters - a hash to use for overriding interpolated references.
    def get_value(overrides = {})
      @value = @generator.call if @value.nil?

      super
    end

  end

end
