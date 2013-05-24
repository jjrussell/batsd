class AddCreativesDictToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :creatives_dict, :text
  end

  def self.down
    remove_column :offers, :creatives_dict
  end
end
