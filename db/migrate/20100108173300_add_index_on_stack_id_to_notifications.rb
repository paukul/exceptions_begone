class AddIndexOnStackIdToNotifications < ActiveRecord::Migration
  def self.up
    add_index :notifications, :stack_id
  end

  def self.down
    remove_index :notifications, :stack_id
  end
end
