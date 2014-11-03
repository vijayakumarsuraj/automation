#
# Suraj Vijayakumar
# 01 Dec 2012
#
require 'weakref'

require 'configuration/error'
require 'configuration/nodes/branch_node'
require 'configuration/nodes/property_node'
require 'configuration/nodes/generated_property_node'
require 'configuration/nodes/root_node'

module Configuration

  class SimpleConfiguration

    # This configuration's root.
    attr_reader :root

    # New empty simple configuration.
    #
    # @param [Hash] properties hash containing properties to initialize the configuration with.
    def initialize(properties = {})
      @root = RootNode.new
      @listeners = []

      add_properties(properties)
    end

    # String representation of this configuration.
    def inspect
      @root.inspect
    end

    # Adds a listener for this configuration.
    #
    # @param [Proc] listener  the listener proc for this configuration.
    def add_listener(listener)
      @listeners << WeakRef.new(listener)
    end

    # Adds a hash of properties to this configuration, merging it with existing branch nodes.
    #
    # @param [Hash] hash hash containing the properties to add.
    # @param [String] target the location in the configuration tree where these properties should be added.
    def add_properties(hash, target = '')
      hash.each_pair do |key, value|
        # Convert the key to a String, unless it was already one.
        key = key.to_s unless key.kind_of?(String)
        full_key = target.empty? ? key : "#{target}.#{key}"
        # Call recursively for hashes. Otherwise add as a property.
        value.kind_of?(Hash) ? add_properties(value, full_key) : add_property(full_key, value)
      end
    end

    # Adds a property to this configuration.
    #
    # @param [String] key the fully qualified key.
    # @param [Object] value the value.
    # @param [Hash] overrides
    #   :overwrite - to overwrite existing properties rather than raise an exception.
    # @return [PropertyNode] the property node that was added to the configuration.
    def add_property(key, value, overrides = {})
      # Convert the key to a String, unless it was already one.
      key = key.to_s unless key.kind_of?(String)
      # Now process the key.
      name, parent_key = split_key(key)
      parent_key_str = parent_key.join('.')
      parent = get_child?(parent_key, create_missing: true)
      raise KeyError.new("'#{parent_key_str}' is not a branch node") unless parent.kind_of?(BranchNode)
      # Process the value.
      value = GeneratedPropertyNode.new(name, &value) if value.kind_of?(Proc)
      value = PropertyNode.new(name, value) unless value.kind_of?(PropertyNode)
      # Add the child and notify all listeners.
      child = value
      parent.add_child(child, overrides)
      notify_listeners('child_added', child)
      # Return the child that was added.
      child
    end

    # Clears all the properties under this configuration.
    def clear
      @root.clear
    end

    # Try to get a child identified by the specified key.
    # Returns false if the child does not exist.
    #
    # @param [String] key the fully qualified key for the required child.
    # @param [Hash] overrides override hash
    # :create_missing - true if missing nodes should be created.
    # @return [Node, FalseClass] the child node or false if the child does not exist.
    def get_child?(key, overrides = {})
      @root.get_child?(key, overrides)
    end

    # Get the property identified by the specified key.
    #
    # @param [String] key the fully qualified key to get.
    # @return [Node] the node.
    def get_value(key, options = {})
      # Convert the key to a String, unless it was already one.
      key = key.to_s unless key.kind_of?(String)
      # Now process the key.
      @root.get_value(key, options)
    end

    # Access properties using [<key>] notation.
    alias [] get_value

    # Check to see if a property with the specified key exists.
    #
    # @param [String] key the fully qualified key.
    # @return [Boolean] true if the child exists, false if it does not.
    def has_property?(key)
      # Convert the key to a String, unless it was already one.
      key = key.to_s unless key.kind_of?(String)
      # Now process the key.
      @root.get_child?(key) ? true : false
    end

    # Merges this configuration with the specified other configuration.
    #
    # @param [SimpleConfiguration] configuration the configuration to merge into this configuration.
    # @param [String] target the target node to merge into - defaults to the root node (i.e. the entire configuration tree is merged).
    # @param [String] source the source node to merge from - defaults to the same value as the target node.
    def merge!(configuration, target = '', source = target)
      target_node = get_child?(target)
      source_node = configuration.get_child?(source)
      # If the source node does not exist, we don't need to merge anything so return immediately.
      return unless source_node
      # If the target node exists, merge the source node in.
      # If it does not exist, we need to create it as a copy of the source node.
      if target_node && target_node.class != source_node.class
        source_details = "#{source_node} (#{source_node.class.name})"
        target_details = "#{target_node} (#{target_node.class.name})"
        raise ConfigurationError.new("Cannot merge incompatible types - Source: #{source_details} - Target: #{target_details}")
      elsif target_node
        target_node.merge!(source_node)
      else
        target_node = source_node.dup
        # Try to add the target node at the appropriate location in the configuration tree.
        _, parent_key = split_key(target)
        parent_key_str = parent_key.join('.')
        parent = get_child?(parent_key, create_missing: true)
        # The required key's parent is not a branch node in the existing configuration.
        raise ConfigurationError.new("Cannot merge '#{target}' with '#{source}' - '#{parent_key_str}' is not a branch node") unless parent.kind_of?(BranchNode)
        parent.add_child(target_node)
      end
    end

    # Removes a property from this configuration.
    def remove_property(key)
      # Convert the key to a String, unless it was already one.
      key = key.to_s unless key.kind_of?(String)
      # Now get the parent node.
      name, parent_key = split_key(key)
      parent_key_str = parent_key.join('.')
      parent = get_child?(parent_key_str)
      raise KeyError.new("Node '#{parent_key_str}' not found") unless parent
      # Remove the child node and notify any listeners.
      child = parent.remove_child(name)
      notify_listeners('child_removed', child) if child
      # Return the child that was removed.
      child
    end

    private

    # Merges the specified hashes recursively.
    #
    # @param [Hash] hash1
    # @param [Hash] hash2
    def deep_merge(hash1, hash2, full_key = '')
      all_keys = (hash1.keys + hash2.keys).uniq
      result = {}
      all_keys.each do |key|
        value1 = hash1[key]
        value2 = hash2[key]
        # If the key is not present in one hash, add the other hash's value to the result.
        if value1.nil?
          result[key] = value2
          next
        elsif value2.nil?
          result[key] = value1
          next
        end
        # Recursive deep merge if the values are hashes.
        # If both are not hashes, use value1.
        # If one is a hash and the other is not, raise an exception.
        if value1.kind_of?(Hash) && value2.kind_of?(Hash)
          full_key = full_key.empty? ? key : "#{full_key}.#{key}"
          result[key] = deep_merge(value1, value2, full_key)
        elsif not (value1.kind_of?(Hash) || value2.kind_of?(Hash))
          result[key] = value1
        else
          full_key = full_key.empty? ? key : "#{full_key}.#{key}"
          raise ConfigurationError.new("Cannot merge incompatible types for '#{full_key}' - '#{value1.class.name}' and '#{value2.class.name}'!")
        end
      end
      # Return
      result
    end

    # Notifies all registered listeners about a change in this configuration.
    #
    # @param [String] action the change action.
    # @param [Array] args arguments.
    def notify_listeners(action, *args)
      @listeners.select! do |listener|
        listener_active = listener.weakref_alive?
        listener.call(action, *args) if listener_active
        listener_active
      end
    end

    # Splits the specified key into a parent node and a name.
    #
    # @param [String] key the key to split.
    # @return [Array<String>] the name and parent key.
    def split_key(key)
      key_parts = key.split('.')
      [key_parts.delete_at(-1), key_parts]
    end

  end

end