class AddInstructionsToOffers < ActiveRecord::Migration
  def self.up
    add_column :generic_offers, :instructions, :text
    add_column :offers, :instructions, :text
  end

  def self.down
    remove_column :offers, :instructions
    remove_column :generic_offers, :instructions, :text
  end
end
