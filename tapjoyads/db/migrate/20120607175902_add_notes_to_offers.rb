class AddNotesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :account_manager_notes, :text
  end

  def self.down
    remove_column :offers, :account_manager_notes
  end
end
