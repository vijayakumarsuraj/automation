#
# Suraj Vijayakumar
# 20 Mar 2013
#

require 'automation/core/mode'

module Automation

  # Special base class for modes that don't execute tests but are there to provide some supporting function.
  class SupportMode < Mode

    private

    # Add additional standard properties.
    def add_standard_properties
      super

      @config_manager.add_override_property('run.config_name', self.class.basename)
    end

    # Overridden to do nothing.
    def configure_test_pack
    end

    # Overridden to do nothing.
    def load_test_pack
    end

    # Overridden to do nothing.
    def publish_result_data
    end

    # Overridden to do nothing.
    def zip_result_directory
    end

  end

end
