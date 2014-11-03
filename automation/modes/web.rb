#
# Suraj Vijayakumar
# 11 Feb 2013
#

require 'automation/modes/support'

module Automation

  # Standard mode for hosting run results.
  class Web < SupportMode

    module CommandLineOptions

      # Method for creating the web database option.
      def option_web_database
        block = proc { |database| save_option_value('database.web_database.database_id', database); propagate_option('--web-database', database) }
        @cl_parser.on('--web-database ID', 'Specify the id of the database to use.',
                      'If skipped, the default specified for the mode is used.', &block)

        block = proc { save_option_value('database.web_database.migrate', true) }
        @cl_parser.on('--web-database-migrate', 'Drop the database schema and then re-create it (all data will be lost!).', &block)

        block = proc { save_option_value('database.web_database.migrate', false) }
        @cl_parser.on('--web-database-upgrade', 'Try to update the the database schema (the default behaviour).', &block)

        block = proc { |flag| save_option_value('database.web_database.logging', flag); propagate_option("--#{flag ? '' : 'no-'}web-database-logging") }
        @cl_parser.on('--[no-]web-database-logging', 'Enable / disable the logging of database calls (SQL queries, model loading)', &block)
      end

      # Method for creating the server option.
      def option_server
        block = proc { |environment| save_option_value('mode.web.environment', environment) }
        @cl_parser.on('--server-environment ENV', 'Specify the environment to use (default: development).', &block)

        block = proc { |host| save_option_value('mode.web.host', host) }
        @cl_parser.on('--server-host HOST', 'Specify the host to bind to (default: 127.0.0.1).', &block)

        block = proc { save_option_value('mode.web.lock', true) }
        @cl_parser.on('--server-lock', 'Turn on mutex locking (default: false).', &block)

        block = proc { |port| save_option_value('mode.web.port', port) }
        @cl_parser.on('--server-port PORT', Integer, 'Specify the port to bind to (default: 8080).', &block)

        block = proc { |server| save_option_value('mode.web.server', server) }
        @cl_parser.on('--server-handler HANDLER', 'Specify the Rack handler to use (default: thin).', &block)

        block = proc { |prefix| save_option_value('mode.web.link_prefix', prefix) }
        @cl_parser.on('--server-link-prefix PREFIX', 'Specify the prefix to be used for links.', &block)
      end

    end

    # Include the WebMode specific command line options.
    include Automation::Web::CommandLineOptions

    def initialize
      super

      # Sinatra will be told to use this logger.
      environment.save('logger', @logger)
    end

    private

    def run
      super
      # The first and ONLY place the web database is created and connected to.
      @web_database = load_component(Component::DatabaseType, 'web_database')
      @web_database.connect
      # Migrate (i.e. recreate the db schema) if required.
      migrate = @config_manager['database.web_database.migrate', default: false]
      migrate ? @web_database.migrate! : @web_database.migrate
      #
      @databases.web_database = @web_database

      @logger.info('Running...')
      require 'web/site.rb'
      WebApp.run!
    end

    # Adds the web specific options.
    def create_mode_options
      option_separator
      option_separator 'Web options:'
      option_web_database

      option_separator
      option_server
    end

  end

end
