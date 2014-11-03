#
# Suraj Vijayakumar
# 22 Mar 2013
#

module Automation

  # Methods for working with MySQL databases.
  module MySQLDatabaseMethods

    # Connection configuration for a MySQL database.
    #
    # @param [Hash] defaults default configuration options.
    # @return [Hash] the connection config.
    def db_mysql_connection_config(defaults)
      database = db_config('database')
      host = db_config('host', default: @config_manager['database.default_host'])
      port = db_config('port', default: @config_manager['database.default_port'])
      username = db_config('username', default: 'framework')
      password = db_config('password', default: 'framework')
      defaults.merge(adapter: 'mysql2', database: database,
                     host: host, port: port,
                     username: username, password: password)
    end

  end

  # Methods for working with Oracle databases.
  module OracleDatabaseMethods

    # Connection configuration for an Oracle database.
    #
    # @param [Hash] defaults default configuration options.
    # @return [Hash] the connection config.
    def db_oracle_connection_config(defaults)
      database = db_config('database')
      username = db_config('username', default: 'framework')
      password = db_config('password', default: 'framework')
      defaults.merge(adapter: 'oracle_enhanced', database: database,
                     username: username, password: password)
    end

  end

  # Methods for working with SQLite3 databases.
  module SQLiteDatabaseMethods

    # Connection configuration for a SQLite database.
    #
    # @param [Hash] defaults default configuration options.
    # @return [Hash] the connection config.
    def db_sqlite_connection_config(defaults)
      file = db_config('file')
      dir = File.dirname(file)
      timeout = db_config('timeout', default: 10) * 1000
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      defaults.merge(adapter: 'sqlite3', database: file, timeout: timeout)
    end

  end

  # Provides database agnostic method extensions / overrides.
  module DatabaseMethods

    include MySQLDatabaseMethods
    include OracleDatabaseMethods
    include SQLiteDatabaseMethods

    # Gets the connection configuration for the current database.
    #
    # @return [Hash] the connection config.
    def db_connection_config
      # Common configuration options.
      pool = db_config('pool', default: 20)
      config = {pool: pool}
      #
      adapter_config_method = "db_#{@adapter}_connection_config"
      if respond_to?(adapter_config_method, true)
        send(adapter_config_method, config)
      else
        raise ConfigurationError.new("Adapter '#{@adapter}' not supported - Method '#{adapter_config_method}' not found")
      end
    end

  end

end
