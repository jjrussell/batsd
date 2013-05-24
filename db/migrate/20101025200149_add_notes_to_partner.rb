class AddNotesToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :account_manager_notes, :text
  end

  def self.down
    remove_column :partners, :account_manager_notes
  end
end
