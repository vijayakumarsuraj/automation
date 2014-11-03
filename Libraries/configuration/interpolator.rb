#
# Suraj Vijayakumar
# 02 Dec 2012
#

require 'singleton'

require 'configuration/error'

module Configuration

  # Simple interpolator that can replace references (${<referenced_key}) with their actual values.
  # References are evaluated within a 'global_context'.
  #
  # The interpolator does *NOT* cache any values, so users should cache values as and when required.
  #
  # This is a singleton class and only one instance of this will ever exist.
  class Interpolator

    # The regular expression to use for replacing property value.
    REPLACE_REGEX = /\A\$\{([\w\d\.:]+)\}\Z/
    # The regular expression to use for interpolating property values.
    INTERPOLATE_REGEX = /\$\{([\w\d\.:]+)\}/

    include Singleton

    # Interpolates the specified value.
    #
    # @param [String] value the value to interpolate.
    # @param [BranchNode] context the global context to use for resolving references.
    # @param [Hash] parameters a hash containing interpolation overrides.
    def interpolate(value, context, parameters)
      if value.kind_of?(String)
        gsub(value, context, parameters)
      elsif value.kind_of?(Array)
        value.map { |item| interpolate(item, context, parameters) }
      else
        value
      end
    end

    # Interpolates the specified property.
    #
    # @param [PropertyNode] property the property to interpolate.
    # @param [BranchNode] context the global context to use for resolving references.
    # @param [Hash] parameters a hash containing interpolation overrides.
    def interpolate_property(property, context, parameters)
      raise InterpolationError.new("Cannot interpolate '#{property}' - it is already being interpolated") if property.interpolating?
      begin
        property.started_interpolate
        interpolate(property.value, context, parameters)
      ensure
        property.finished_interpolate
      end
    end

    private

    # Get the value of a particular reference.
    #
    # @param [String] key the reference whose value is required.
    # @param [BranchNode] context the global context for resolving references.
    # @param [Hash] parameters a hash containing interpolation overrides.
    def get_reference_value(key, context, parameters)
      if key.start_with?('env.')
        env_key = key[4..-1]
        raise InterpolationError.new("Cannot interpolate '#{key}' - ENV[#{env_key}] not defined") unless ENV.has_key?(env_key)
        ENV[env_key]
      elsif parameters.has_key?(key)
        parameters[key]
      else
        context.get_value(key, parameters: parameters)
      end
    end

    # Perform the interpolation using the 'gsub' function.
    #
    # @param [String] value the value to interpolate.
    # @param [BranchNode] context the global context for resolving references.
    # @param [Hash] parameters a hash containing interpolation overrides.
    def gsub(value, context, parameters)
      # Try to find a full replacement match - if found, return the actual value of that reference.
      return get_reference_value($1, context, parameters) if value.match(REPLACE_REGEX)
      # No full match, substitute all references with their string representations
      value.gsub(INTERPOLATE_REGEX) { get_reference_value($1, context, parameters) }
    end

  end

end
