#
# Suraj Vijayakumar
# 01 Dec 2012
#

require 'configuration/nodes/branch_node'

module Configuration

  # Special root node for a SimpleConfiguration. It behaves exactly like a branch node.
  # The only difference is that this node cannot be referenced since it does not have a name.
  class RootNode < BranchNode

    # New empty root node.
    def initialize
      super('ROOT')
    end

    # Overridden to duplicate all children and this node.
    def dup
      self_dup = RootNode.new
      each_child { |child| self_dup.add_child(child.dup) }
      self_dup
    end

    # Overridden to always return false.
    #
    # @return [FalseClass] always false.
    def has_name?
      false
    end

  end

end