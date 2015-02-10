#
# Suraj Vijayakumar
# 10 Feb 2015
#

require 'automation/modes/support'

module Automation

  # Overrides for when the 'test' feature is enabled.
  class SupportMode < Mode

    private

    # Overridden to do nothing.
    def configure_test_pack
    end

    # Overridden to do nothing.
    def load_test_pack
    end

  end

end
