class AddUniqueConstraintToApprovals < ActiveRecord::Migration
  def self.up
    add_index :approvals, :id, :unique => true
  end

  def self.down
    remove_index :approvals, :id, :unique => true
  end
end
