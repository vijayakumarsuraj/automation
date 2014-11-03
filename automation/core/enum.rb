#
# Suraj Vijayakumar
# 20 May 2013
#

module Automation

  # A simple enum like object.
  class Enum

    # Creates an enum that will registered with the specified name.
    #
    # @return [Enum] the enum instance.
    def self.create(value, *args)
      # Define the ByValue array, unless it is already defined.
      const_set(:ByValue, []) unless const_defined?(:ByValue)
      # Don't allow defining two enums with the same ordinal value.
      by_value = const_get(:ByValue)
      raise "Enum #{self.class.name} with ordinal '#{value}' already defined" unless by_value[value].nil?
      # Create the enum.
      by_value[value] = new(value, *args)
    end

    # Gets an enum object for the specified value.
    #
    # @param [Integer] value the value to get an enum for.
    # @return [Enum] the enum object.
    def self.from_value(value)
      # Define the ByValue array, unless it is already defined.
      const_set(:ByValue, []) unless const_defined?(:ByValue)
      # Get the saved enum reference.
      value.nil? ? nil : const_get(:ByValue)[value]
    end

    attr_reader :value

    # The value associated with the enum.
    # All comparisons (>, <, ==, etc...) are done using the specified value.
    #
    # @param [Integer] value the ordinal value of this enum.
    def initialize(value)
      @value = value
    end

    # Compares with another enum using '<'.
    #
    # @param [Enum] other the other enum.
    def <(other)
      @value < other.value
    end

    # Compares with another enum using '>'.
    #
    # @param [Enum] other the other enum.
    def >(other)
      @value > other.value
    end

    # Compares with another enum using '<='.
    #
    # @param [Enum] other the other enum.
    def <=(other)
      @value <= other.value
    end

    # Compares with another enum using '>='.
    #
    # @param [Enum] other the other enum.
    def >=(other)
      @value >= other.value
    end

    # Compares with another enum using '=='.
    #
    # @param [Enum] other the other enum.
    def ==(other)
      @value == other.value
    end

    # Compares with another enum using '!='.
    #
    # @param [Enum] other the other enum.
    def !=(other)
      @value != other.value
    end

    # Compares with another enum using '<=>'.
    #
    # @param [Enum] other the other enum.
    def <=>(other)
      @value <=> other.value
    end

  end

end
