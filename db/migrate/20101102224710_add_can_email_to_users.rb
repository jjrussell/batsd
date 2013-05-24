class AddCanEmailToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :can_email, :boolean, :default => true
  end

  def self.down
    remove_column :users, :can_email
  end
end
