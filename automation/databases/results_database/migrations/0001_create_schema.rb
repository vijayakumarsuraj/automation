#
# Suraj Vijayakumar
# 20 Mar 2013
#

require 'active_record/migration'

class CreateSchema < ActiveRecord::Migration

  # Include the automation kernel.
  include Automation::Kernel

  def change
    change_applications_table
    change_change_events_table

    change_vcs_repos_table
    change_run_configs_table
    change_run_properties_table
    change_run_results_table

    change_task_results_table
    change_tasks_table

    change_test_results_table
    change_tests_table
  end

  def change_applications_table
    create_table :applications do |t|
      t.column :application_name, :string, limit: 255
    end
  end

  def change_change_events_table
    create_table :change_events do |t|
      t.column :value, :integer
      t.column :issue, :string, limit: 255

      t.references :run_result, :test # Each change is associated with a run result and a test.
    end

    add_index :change_events, [:test_id]
    add_index :change_events, [:run_result_id]
  end

  def change_vcs_repos_table
    create_table :vcs_repos do |t|
      t.column :url, :string, limit: 4097
      t.column :vcs_type, :string, limit: 255
      t.column :username, :string, limit: 255
      t.column :password, :string, limit: 255
    end
  end

  def change_run_configs_table
    create_table :run_configs do |t|
      t.column :config_name, :string, limit: 255

      t.references :application # Each config is associated with an application.
    end
  end

  def change_run_properties_table
    create_table :run_properties do |t|
      t.column :key, :string, limit: 255
      t.column :value, :text

      t.references :run_result # Each property is associated with a run result.
    end
  end

  def change_run_results_table
    create_table :run_results do |t|
      t.column :run_name, :string, limit: 255
      t.column :user, :string, limit: 255
      t.column :official, :boolean
      t.column :result, :integer # The value of this column has application specific meanings.
      t.column :status, :integer # The value of this column has application specific meanings.
      t.column :mode, :string, limit: 255
      t.column :summary, :string, limit: 255
      t.column :start_date_time, :datetime
      t.column :end_date_time, :datetime

      t.references :run_config # Each run is associated with a config.
    end

    add_index :run_results, [:run_name]
    add_index :run_results, [:run_config_id]
  end

  def change_task_results_table
    create_table :task_results do |t|
      t.column :result, :integer # The value of this column has application specific meanings.
      t.column :status, :integer # The value of this column has application specific meanings.
      t.column :properties, :text
      t.column :start_date_time, :datetime
      t.column :end_date_time, :datetime

      t.references :task, :run_result # Each task result is associated with a task and a run.
    end

    add_index :task_results, [:run_result_id]
    add_index :task_results, [:task_id]
  end

  def change_tasks_table
    create_table :tasks do |t|
      t.column :task_name, :string, limit: 255

      t.references :run_config # Each task is associated with a config.
    end

    add_index :tasks, [:task_name]
    add_index :tasks, [:run_config_id]
  end

  def change_test_results_table
    create_table :test_results do |t|
      t.column :result, :integer # The value of this column has application specific meanings.
      t.column :status, :integer # The value of this column has application specific meanings.
      t.column :properties, :text
      t.column :start_date_time, :datetime
      t.column :end_date_time, :datetime

      t.references :test, :run_result # Each test result is associated with a test and a run.
    end

    add_index :test_results, [:run_result_id]
    add_index :test_results, [:test_id]
  end

  def change_tests_table
    create_table :tests do |t|
      t.column :test_name, :string, limit: 255
      t.column :test_description, :string, limit: 1000
      t.column :test_category, :string, limit: 255
      t.column :type_name, :string, limit: 255

      t.references :run_config # Each test is associated with a run.
    end

    add_index :tests, [:test_name]
    add_index :tests, [:test_category]
    add_index :tests, [:test_name, :type_name, :run_config_id], unique: true
  end

end
