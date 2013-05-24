class ChangeIndexToNonUnique < ActiveRecord::Migration
  def self.up
    remove_index :offers, [:tracking_for_type, :tracking_for_id]
    add_index :offers, [:tracking_for_type, :tracking_for_id]
  end

  def self.down
    remove_index :offers, [:tracking_for_type, :tracking_for_id]
    add_index :offers, [:tracking_for_type, :tracking_for_id], :unique => true
  end
end
