#
# Suraj Vijayakumar
# 16 Jan 2014
#

require 'active_record/migration'

class CreateSchema < ActiveRecord::Migration

  # Include the automation kernel.
  include Automation::Kernel

  def change
    change_users_table
  end

  def change_users_table
    create_table :users do |t|
      t.column :username, :string, limit: 50
      t.column :password, :string, limit: 64
      t.column :salt, :string, limit: 8
      t.column :display_name, :string, limit: 255
    end

    add_index(:users, :username, unique: true)
  end

end
