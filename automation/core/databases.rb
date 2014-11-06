#
# Suraj Vijayakumar
# 15 Jan 2014
#

require 'automation/core/component'

module Automation

  # Represents a collection of all active databases.
  class Databases < Component

    # The results database.
    attr_accessor :results_database

    def initialize
      super

      @component_name = @component_name.snakecase
      @component_type = Automation::Component::CoreType

      @results_database = nil
      @databases = {}
    end

    # Adds a database to this collection.
    #
    # @param [String] key
    # @param [Automation::Database] value
    def add_database(key, value)
      @databases[key] = value
    end

    # Iterate over this collection yielding each database in turn.
    # Automatically connects to databases as required.
    def each
      # First yield the results databases.
      yield 'results', @results_database unless @results_database.nil?
      # Then all other databases.
      @databases.each_key do |key|
        db = get_database(key)
        yield key, db unless db.nil?
      end
    end

    # Gets a database from this collection.
    # This method will also establish a connection to the database.
    #
    # @param [String] key
    # @return [Automation::Database]
    def get_database(key)
      return nil unless @databases.has_key?(key)

      # Get the database entry.
      # If it is a 'Proc' then execute the proc and use the value that is returned.
      db = @databases[key]
      db = db.call if db.kind_of?(Proc)
      # Connect to the database, if required and return.
      db.connect_and_migrate
      db
    end

    alias []= add_database
    alias [] get_database

    private

  end

end
