#
# Suraj Vijayakumar
# 22 Mar 2013
#

require 'automation/core/component'
require 'automation/support/database_methods'

module Automation

  # The base class for databases used by the framework.
  class Database < Component

    # The base class for all model classes.
    class BaseModel < ActiveRecord::Base
      self.abstract_class = true
    end

    # Provides database agnostic method extensions / overrides.
    include Automation::DatabaseMethods

    # New database identified by the specified name.
    def initialize
      super

      @component_name = @component_name.snakecase
      @component_type = Automation::Component::DatabaseType
      @connected = false

      # Database details from the configuration.
      @database_id = @config_manager["database.#{@component_name}.database_id"]
      @adapter = db_config('adapter', default: false)
      raise ConfigurationError.new("No adapter defined for database '#{@component_name}.#{@database_id}'") unless @adapter
      # Get the adapter specific connection specification and establish the connection on all required models.
      @connection_config = db_connection_config
    end

    # Cleans this database by removing any stale records.
    def clean
    end

    # Connects to the database. Will do nothing if already connected.
    def connect
      return if @connected

      @logger.info('Connecting...')
      sql_logger = Logging::Logger["#{self.class.name}::SQL"]
      sql_logger.level = db_config('logging', default: @config_manager["database.#{@component_name}.logging"])
      # Establish the connection.
      base_model.logger = sql_logger
      base_model.establish_connection(@connection_config)
      # Mark as connected.
      @connected = true
    end

    # Connects to the database and migrates to the latest version.
    def connect_and_migrate
      return if @connected

      connect
      migrate
    end

    # Updates the database to the latest schema by dropping the existing schema and re-creating it.
    def migrate!
      @logger.fine('Dropping schema...')

      migrate(0) # migrate to version 0.
      migrate # migrate to latest version.
    end

    # Executes the specified block within a transaction.
    def with_transaction(&block)
      base_model.transaction(&block)
    end

    # Executes the specified block with a connection.
    def with_connection(&block)
      base_model.connection_pool.with_connection(&block)
    end

    private

    # Get the base model for this database.
    def base_model
      raise ConfigurationError.new("Base model not defined for '#{self.class.name}'")
    end

    # Gets the value of a database configuration.
    #
    # @param [String] key the configuration key
    # @param [Hash] options optional hash of options.
    def db_config(key, options = {})
      @config_manager["database.#{@component_name}.#{@database_id}.#{key}", options]
    end

    # Update the database schema to the specified version.
    #
    # @param [Integer] version the version to migrate to. If nil, migrates to the latest version.
    def migrate(path, version = nil)
      # Establish a connection for migration.
      ActiveRecord::Base.establish_connection(@connection_config)
      ActiveRecord::Migration.verbose = false
      # Namespace definition for the current database.
      # This will ensure that each database is migrated independently.
      ActiveRecord::Base.table_name_prefix = base_model.table_name_prefix
      ActiveRecord::Migrator.migrate(path, version)
      # Clean-up once done.
      ActiveRecord.send(:remove_const, :SchemaMigration)
      load 'active_record/schema_migration.rb'
      ActiveRecord::Base.table_name_prefix = ''
      ActiveRecord::Base.connection.close
    end

  end

end