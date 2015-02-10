#
# Suraj Vijayakumar
# 16 Jan 2014
#

require 'active_record/migration'

class CreateTestDatabaseSchema < ActiveRecord::Migration

  def change
    change_change_events_table

    change_test_results_table
    change_tests_table
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
