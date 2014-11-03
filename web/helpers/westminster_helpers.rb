#
# Suraj Vijayakumar
# 06 Jun 2014
#

module Automation

  # Provides methods for accessing and working with the Reval database.
  module WestminsterHelpers

    # Performs initializations that are specific to the Westminster.
    def westminster_before
      @defaults['westminster'] = {}
      @defaults['westminster']['show_passing_tests_enabled'] = true
      @defaults['westminster']['show_passing_tests'] = false
    end

  end

end
