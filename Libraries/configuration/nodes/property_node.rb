#
# Suraj Vijayakumar
# 01 Dec 2012
#

require 'configuration/error'
require 'configuration/interpolator'
require 'configuration/node'

module Configuration

  # A simple node that can store a value.
  class PropertyNode < Node

    # The raw value of this property.
    attr_accessor :value

    # Creates a new property with the specified
    #
    # @param [String] name the name of the property.
    # @param [Object] value the value of this property.
    def initialize(name, value)
      super(name)

      @value = value
      @interpolating = false
    end

    # Overridden to create a duplicate of this PropertyNode.
    def dup
      PropertyNode.new(@name, @value)
    end

    # Overridden to return the raw value of this property.
    def inspect
      full_name.inspect
    end

    # Overridden to copy all properties from the node being merged in.
    def merge!(other)
      @value = other.value
    end

    # Returns the content of this property node. Useful for debugging.
    def dump
      "#{@name.inspect} => #{@value.inspect}"
    end

    # Mark this property to indicate that interpolation has finished.
    def finished_interpolate
      @interpolating = false
    end

    # Get the value of this property.
    #
    # @param [Hash] overrides overrides to apply while evaluating the property's value.
    # :interpolate - true if the value should be interpolated, false to return the raw value.
    # :context - the global context to use when interpolating references.
    # :parameters - a hash to use for overriding interpolated references.
    def get_value(overrides = {})
      defaults = {interpolate: true, parameters: {}}
      overrides = defaults.merge(overrides)
      #
      interpolate = overrides[:interpolate]
      context = overrides[:context]
      parameters = overrides[:parameters]
      #
      if interpolate
        raise InterpolationError.new('Cannot interpolate - no context') if context.nil?

        begin
          interpolator = Interpolator.instance
          interpolator.interpolate_property(self, context, parameters)
        rescue KeyError, InterpolationError => ex
          raise ex.class.new("#{self} -> #{ex.message}", ex)
        end
      else
        @value
      end
    end

    # Check to see if this property is currently being interpolated.
    #
    # @return [Boolean] true if interpolating, false otherwise.
    def interpolating?
      @interpolating
    end

    # Mark this property to indicate that interpolation has started.
    def started_interpolate
      @interpolating = true
    end

  end

end