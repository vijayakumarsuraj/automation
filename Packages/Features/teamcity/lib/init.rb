#
# Suraj Vijayakumar
# 14 Nov 2014
#

module Automation

  class Mode

    module CommandLineOptions

      # Method for creating TeamCity options.
      def option_teamcity
        block = proc { save_option_value('task.observer.team_city', true); propagate_option('--team-city-observer') }
        @cl_parser.on('--team-city-observer', 'Add the TeamCity observer to this run so that status updates are reported to TeamCity.', "Requires the 'teamcity' feature", &block)
      end

    end

    # Creates the options TeamCity supports.
    def create_feature_options_with_teamcity
      create_feature_options_without_teamcity
      option_separator
      option_separator 'TeamCity specific options:'
      option_teamcity
    end

    alias_method_chain :create_feature_options, :teamcity

  end

end