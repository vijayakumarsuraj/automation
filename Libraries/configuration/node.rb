#
# Suraj Vijayakumar
# 01 Dec 2012
#

module Configuration

  # The base class for all nodes that form part of a configuration tree.
  class Node

    # The name of this node.
    attr_reader :name
    # The parent.
    attr_reader :parent

    # Creates a new empty node.
    #
    # @param [String] name the name of this node.
    def initialize(name)
      @name = name
      @parent = nil
    end

    # Duplicate this node completely.
    #
    # @return [Node] the duplicated node.
    def dup
      raise NotImplementedError.new("Method 'dup' not implemented by '#{self.class.name}'")
    end

    # Merges two nodes of the same type. This will overwrite this node.
    # Implementations should ensure that the node being merged in is not modified in any way.
    #
    # @param [Node] other the node to merge in.
    def merge!(other)
      raise NotImplementedError.new("Method 'merge!' not implemented by '#{self.class.name}'")
    end

    # Overridden to return the full name.
    def to_s
      full_name
    end

    # Get the full name of this node. This will traverse the node hierarchy each time.
    #
    # @return [String] The full name of this node.
    def full_name
      (@parent.nil? or not @parent.has_name?) ? @name : "#{@parent.full_name}.#{@name}"
    end

    # Check to see if this node has any children.
    #
    # @return [Boolean]
    def has_children?
      false
    end

    # Check to see if the parent has a name.
    #
    # @return [Boolean] true if the parent has a name, returns false otherwise.
    def has_name?
      true
    end

    protected

    # Set the parent of this node.
    #
    # @param [Node] parent_node the parent of this node.
    # @return [Node] The parent node.
    def set_parent(parent_node)
      @parent = parent_node
    end

  end

end
