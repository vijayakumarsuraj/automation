#
# Suraj Vijayakumar
# 13 Feb 2013
#

module Automation

  # Provides methods for accessing the databases collection.
  module DatabaseHelpers

    # Destroys the specified run result.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    def db_destroy_run_result(run_result)
      @databases.each { |db| db.before_destroy_run_result(run_result) if db.respond_to?(:before_destroy_run_result) }
      run_result.destroy
    end

  end

end
