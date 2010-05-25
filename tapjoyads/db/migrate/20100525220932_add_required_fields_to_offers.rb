class AddRequiredFieldsToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :instructions, :text
    add_column :offers, :time_delay, :string
    add_column :offers, :credit_card_required, :boolean, :default => false, :null => false
    remove_column :rating_offers, :instructions
  end

  def self.down
    remove_column :offers, :instructions
    remove_column :offers, :time_delay
    remove_column :offers, :credit_card_required
    add_column :rating_offers, :instructions, :text
  end
end
