#
# Suraj Vijayakumar
# 22 Mar 2013
#

require 'automation/core/database'

module Automation

  # The results database. Stores information relating to the results of each run.
  class ResultsDatabase < Automation::Database

    module FindMethods

      # Get the RunResult entity for the specified task id.
      #
      # @param [String] result_id the result id.
      # @return [Automation::ResultsDatabase::RunResult] the run result.
      def find_run_result(result_id)
        RunResult.find(result_id)
      rescue
        nil
      end

      # Get the TaskResult entity for the specified task id.
      #
      # @param [String] result_id the result id.
      # @return [Automation::ResultsDatabase::TaskResult] the task result.
      def find_task_result(result_id)
        TaskResult.find(result_id)
      rescue
        nil
      end

    end

    module CreateMethods

      # Creates a RunResult entity for the current run.
      #
      # @param [Automation::ResultsDatabase::RunConfig] run_config the run configuration to which this result belongs.
      def create_run_result(run_config)
        run_name = @config_manager['run.name']
        RunResult.create(run_config: run_config, start_date_time: DateTime.now, run_name: run_name)
      end

      # Creates a TaskResult entity for the specific task run.
      #
      # @param [Automation::ResultsDatabase::RunResult] run_result the run this task result belongs.
      # @param [Automation::ResultsDatabase::Task] task the task.
      def create_task_result(run_result, task)
        TaskResult.create(run_result: run_result, task: task, start_date_time: DateTime.now)
      end

    end

    module GetCreateMethods

      # Gets the Application entity for the current run. Creates it if required.
      #
      # @param [String] application the name of the application.
      # @return [Automation::ResultsDatabase::Application] the application.
      def get_application!(application = @config_manager['run.application'])
        Application.where(application_name: application).first_or_create
      end

      # Get the RunConfig entity for the current run. Creates it if required.
      #
      # @return [Automation::ResultsDatabase::RunConfig] the run  config.
      # @param [String] config_name the name of the configuration.
      # @param [String] application the application.
      def get_run_config!(config_name = @config_manager['run.config_name'], application = get_application!)
        RunConfig.where(config_name: config_name, application_id: application).first_or_create
      end

      # Creates a Task entity for the specified task.
      #
      # @param [Automation::ResultsDatabase::RunConfig] run_config the run config.
      # @param [String] task_name the task name.
      def get_task!(run_config, task_name)
        task = Task.where(task_name: task_name, run_config_id: run_config).first_or_create
        task.save
        task
      rescue ActiveRecord::StatementInvalid
        Task.where(task_name: task_name, run_config_id: run_config).first
      end

    end

    require 'automation/results_database/models'

    include FindMethods
    include CreateMethods
    include GetCreateMethods

    # Removes stale rows from the following:
    # RunConfig, Task and Application
    def clean
      super

      with_connection do |connection|
        connection.execute(SQL_DELETE_RUN_CONFIGS)
        connection.execute(SQL_DELETE_TASKS)
        connection.execute(SQL_DELETE_APPLICATIONS)
      end
    end

    # Update the database schema to the specified version.
    #
    # @param [Integer] version the version to migrate to. If nil, migrates to the latest version.
    def migrate(version = nil)
      @logger.fine('Running core migrations...')
      super(File.join(FRAMEWORK_ROOT, 'automation/results_database/migrations'), version)
    end

    # Gets the next run result for the specified run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [Boolean] skip_exception if true, runs whose result is > Fail are not counted.
    # @param [Boolean] skip_non_official if true, runs whose official flag is false are not counted.
    # @return [Automation::ResultsDatabase:RunResult] the next run result.
    def get_next_run_result(run_result, skip_exception = true, skip_non_official = true)
      run_config = run_result.run_config
      run_id = run_result.id
      results = RunResult.where(run_config_id: run_config).where('id > ?', run_id)
      # Filter rows with result > failed if the skip_exception flag is true.
      failed_value = Result::Fail.value
      results = results.where('result <= ?', failed_value) if skip_exception
      results = results.where(official: true) if skip_non_official
      # The first row is the next result.
      results.first
    end

    # Gets the previous run result for the specified run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [Boolean] skip_exception if true, runs whose result is > Fail are not counted.
    # @param [Boolean] skip_non_official if true, runs whose official flag is false are not counted.
    # @return [Automation::ResultsDatabase:RunResult] the previous run result.
    def get_previous_run_result(run_result, skip_exception = true, skip_non_official = true)
      run_config = run_result.run_config
      run_id = run_result.id
      results = RunResult.where(run_config_id: run_config).where('id < ?', run_id)
      # Filter rows with result > failed if the skip_exception flag is true.
      failed_value = Result::Fail.value
      results = results.where('result <= ?', failed_value) if skip_exception
      results = results.where(official: true) if skip_non_official
      # The last row is the previous result.
      results.last
    end

    # Get the run property with the specified key. Returns 'value' if such a property does not exist.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] key the property to get.
    # @param [Object] value the default value to return if a property does not exist.
    def get_run_property(run_result, key, value = nil)
      property = RunProperty.where(run_result_id: run_result, key: key).first
      property.nil? ? value : property.value
    end

    # Get the run property with the specified key. Returns 'value' if such a property does not exist.
    # Parses the property as a YAML string and returns the generated hash.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] key the property to get.
    # @param [Object] value the default value to return if a property does not exist.
    def get_run_property_yaml(run_result, key, value = {})
      property = get_run_property(run_result, key)
      property.nil? ? value : YAML.load(property)
    end

    # Get the RunResult entity for the current run.
    #
    # @param [String] run_name the name of the run (defaults to the current run)
    # @return [Automation::ResultsDatabase::RunResult] the run result.
    def get_run_result(run_name = @config_manager['run.name'])
      RunResult.where(run_name: run_name).first
    end

    # Gets the task results for all the tasks with the specified name.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] task_name the name of the task.
    # @param [Array<Automation::ResultsDatabase::TaskResult>]
    def get_task_results(run_result, task_name)
      run_result.task_results.joins(:task).where(task: {task_name: task_name})
    end

    # Deletes the specified run property.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result
    # @param [String] key
    def remove_run_property(run_result, key)
      property = RunProperty.where(run_result_id: run_result, key: key).first
      property.destroy unless property.nil?
    end

    # Sets the specified key-value pair as a property for the specified run.
    #
    # @param [Automation::ResultsDatabase::RunResult] run_result the run result.
    # @param [String] key the property's key.
    # @param [String] value the property's value.
    def set_run_property(run_result, key, value)
      property = RunProperty.where(run_result_id: run_result, key: key).first_or_create(value: value)
      property.save
      property
    end

    private

    # The base model for the results database.
    def base_model
      BaseModel
    end

  end

end

RESULTS_DATABASE_TABLE_PREFIX = Automation::ResultsDatabase::BaseModel.table_name_prefix

#
# Miscellaneous clean-up queries.
#
SQL_DELETE_RUN_CONFIGS = <<-SQL
DELETE
FROM #{RESULTS_DATABASE_TABLE_PREFIX}run_configs
WHERE id NOT IN (
  SELECT DISTINCT(run_config_id)
  FROM #{RESULTS_DATABASE_TABLE_PREFIX}run_results
)
SQL

SQL_DELETE_TASKS = <<-SQL
DELETE
FROM #{RESULTS_DATABASE_TABLE_PREFIX}tasks
WHERE id NOT IN (
  SELECT DISTINCT(task_id)
  FROM #{RESULTS_DATABASE_TABLE_PREFIX}task_results
)
SQL

SQL_DELETE_APPLICATIONS = <<-SQL
DELETE
FROM #{RESULTS_DATABASE_TABLE_PREFIX}applications
WHERE id NOT IN (
  SELECT DISTINCT(application_id)
  FROM #{RESULTS_DATABASE_TABLE_PREFIX}run_configs
)
SQL
