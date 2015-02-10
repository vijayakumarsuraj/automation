#
# Suraj Vijayakumar
# 06 Mar 2013
#

module Automation

  # Provides a singleton environment to store global data.
  class Runtime

    include Singleton

    def initialize
    end

    # Check if the specified key is defined.
    #
    # @param [Symbol] key
    # @return [Boolean]
    def defined?(key)
      respond_to?(key, true)
    end

    # Saves a value to the automation environment.
    #
    # @param [Object] key the key against which to save the value.
    # @param [Object] value the value.
    def save(key, value)
      Runtime.send(:define_method, key) { value }
    end

  end

end
