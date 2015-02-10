#
# Suraj Vijayakumar
# 01 Dec 2012
#

require 'configuration/error'
require 'configuration/interpolator'
require 'configuration/node'
require 'configuration/nodes/property_node'

module Configuration

  # A branch node is a special node that can contain child nodes. It provides support for
  # '.' separated keys to represent a path (e.g. get_value("grandparent.parent.node") will return
  # first find the property 'node' within the branch 'parent' within the child 'grandparent').
  #
  # It also provides support to merge with another arbitrary branch - all children are also merged.
  #
  # This class forms the base on which the SimpleConfiguration class operates.
  class BranchNode < Node

    DEFAULTS_KEY = '__defaults__'

    # Creates a new empty branch.
    #
    # @param [String] name the name of this branch.
    def initialize(name)
      super(name)
      @children = {}
    end

    # Overridden to duplicate all children and this node.
    def dup
      self_dup = BranchNode.new(@name)
      each_child { |child| self_dup.add_child(child.dup) }
      self_dup
    end

    # Overridden to return the full name of this node.
    def inspect
      full_name
    end

    # Merge this branch node with another branch node.
    def merge!(other)
      other = other.dup
      other.each_child do |other_child|
        my_child = get_child?(other_child.name)
        # Directly add if a child with the same name does not already exist.
        # Merge if the other child and my child are nodes.
        # Raise an exception otherwise.
        if not my_child
          add_child(other_child)
        elsif my_child.class == other_child.class
          my_child.merge!(other_child)
        else
          source_details = "#{other_child} (#{other_child.class.name})"
          target_details = "#{my_child} (#{my_child.class.name})"
          raise ConfigurationError.new("Cannot merge incompatible types - Source: #{source_details} - Target: #{target_details}")
        end
      end
    end

    # Updates the value of the specified property node.
    #
    # @param [String] key the node to update.
    # @param [Object] new_value the new value.
    def []=(key, new_value)
      key = key.to_s unless key.kind_of?(String)
      if (node = get_child?(key))
        # Raise an exception if the child is not a property node.
        raise KeyError.new("Node '#{self.has_name? ? "#{self}." : ''}.#{key}' is not a property") unless node.kind_of?(PropertyNode)
        # Update the property's value.
        node.value = new_value
      else
        # The required node does not exist.
        raise KeyError.new("Node '#{self.has_name? ? "#{self}." : ''}#{key}' not found")
      end
    end

    # Adds the specified node as a child of this node.
    # If a node with the same name already exists, an exception is raised.
    #
    # @param [Node] child the node to add.
    # @return [Node] The child node.
    def add_child(child, overrides = {})
      defaults = {overwrite: false}
      overrides = defaults.merge(overrides)
      # If true, overwrite
      overwrite = overrides[:overwrite]
      # Remove existing children if overwrite is true.
      # Raise an exception if overwrite is false and a child with the same name exists.
      child_name = child.name
      if overwrite
        remove_child(child_name)
      elsif @children.has_key?(child_name)
        raise KeyError.new("'#{self}' already contains child '#{child_name}'")
      end
      # Add the child.
      child.set_parent(self)
      @children[child_name] = child
    end

    # Removes all the children under this node. Recursively clears its children also.
    def clear
      each_child { |child| child.clear if child.kind_of?(BranchNode) }
      @children.clear
    end

    # Yields each child under this branch.
    def each_child
      @children.each_pair { |_, child| yield child }
    end

    # Returns the content of this branch node. Useful for debugging.
    def dump
      str_array = []
      @children.each_pair { |_, value| str_array << value.dump }
      str_array.join(', ')
    end

    # Try to get a child identified by the specified key.
    # Returns false if the child does not exist.
    #
    # @param [String] key the fully qualified key for the required child.
    # @param [Hash] overrides override hash
    # :create_missing - true if missing nodes should be created.
    # @return [Node, FalseClass] the child node or false if the child does not exist.
    def get_child?(key, overrides = {})
      defaults = {create_missing: false, context: self}
      overrides = defaults.merge(overrides)
      # If true, create
      create_missing = overrides[:create_missing]
      # Split the key if it is a String - otherwise leave it as is.
      key_parts = key.kind_of?(String) ? key.split('.') : key
      # If the length of the key parts is 0, then it is a reference to this node.
      return self if key_parts.length == 0
      # Get the name to look up in this branch.
      name = key_parts.delete_at(0)
      # If a child with this name exists, use it.
      # If create_missing is false and '__defaults__' is defined, look for the child under the "default" node specified.
      # If the create_missing flag is false, return false. If it is true, create the node (and all child nodes too)
      if @children.has_key?(name)
        node = @children[name]
      elsif !create_missing && @children.has_key?(DEFAULTS_KEY)
        defaults_key = get_value(DEFAULTS_KEY, interpolate: false)
        node = overrides[:context].get_child?(defaults_key, overrides).get_child?(name, overrides)
      else
        node = nil
      end
      if node
        # If there are more key parts to process, then delegate it to the child node.
        # Otherwise return the node.
        raise KeyError.new("'#{node}' is not a branch") if key_parts.length > 0 && !node.kind_of?(BranchNode)
        return node.get_child?(key_parts, overrides) if key_parts.length > 0
        return node
      elsif create_missing
        # Create this node and any child nodes too and return the last node in the chain.
        node = add_child(BranchNode.new(name))
        key_parts.each { |part| node = node.add_child(BranchNode.new(part)) }
        return node
      end
      # Return false if the node was not found.
      false
    end

    # Gets the value of the specified child. Raises an exception if the child does not resolve to a property node, or
    # if such a child does not exist.
    def get_value(key, overrides = {})
      defaults = {interpolate: true, context: self}
      overrides = defaults.merge(overrides)
      # Get the child represented by the specified key.
      child = get_child?(key.to_s, context: overrides[:context])
      # If the child does not exist, and a default value was provided, return that. Otherwise raise an exception.
      unless child
        if overrides.has_key?(:default)
          return overrides[:default]
        else
          raise KeyError.new("Node '#{self.has_name? ? "#{self}." : ''}#{key}' not found")
        end
      end
      # Raise an exception if the child is not a property node too.
      raise KeyError.new("Node '#{self.has_name? ? "#{self}." : ''}#{key}' is not a property") unless child.kind_of?(PropertyNode)
      # Return the value.
      child.get_value(overrides)
    end

    # Can also access values using the [key] operator.
    alias [] get_value

    # Check to see if this node has any children.
    #
    # @return [Boolean]
    def has_children?
      @children.length > 0
    end

    # Yields each child under this branch.
    # Returns an array of the items returned by the block.
    def map_child
      array = []
      @children.each_pair { |_, child| array << (yield child) }
      array
    end

    # Removes the specified child from this node. Returns the child that was removed, or nil.
    #
    # @param [String] child_name the name of the child to remove.
    # @return [Node] the child that was removed or nil.
    def remove_child(child_name)
      child = @children.delete(child_name)
      child.set_parent(nil) unless child.nil?
      child
    end

    # Converts this branch node to a hash - all values are returned after interpolation.
    def to_hash(overrides = {})
      defaults = {interpolate: true, context: self}
      overrides = defaults.merge(overrides)
      hash = {}
      @children.each_pair do |name, child|
        if child.kind_of?(BranchNode)
          hash[name] = child.to_hash(overrides)
        elsif child.kind_of?(PropertyNode)
          hash[name] = child.get_value(overrides)
        end
      end
      # Return the hash.
      hash
    end

  end

end
