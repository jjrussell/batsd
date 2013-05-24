class AddMultiCompleteToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :multi_complete, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :multi_complete
  end
end
