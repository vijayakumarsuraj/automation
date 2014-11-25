#
# Suraj Vijayakumar
# 11 Nov 2014
#

module Automation::SqlServer

  # Methods for working with SQLServer databases.
  module DatabaseMethods

    # Connection configuration for an SqlServer database.
    #
    # @param [Hash] defaults default configuration options.
    # @return [Hash] the connection config.
    def db_sqlserver_connection_config(defaults)
      database = db_config('database')
      dataserver = db_config('dataserver', default: @config_manager['database.default_dataserver'])
      username = db_config('username', default: 'framework')
      password = db_config('password', default: 'framework')
      defaults.merge(adapter: 'sqlserver', database: database, dataserver: dataserver,
                     username: username, password: password)
    end

  end

end

module Automation

  module DatabaseMethods
    include Automation::SqlServer::DatabaseMethods
  end

end
