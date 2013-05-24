class AddRewardValueToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :reward_value, :integer
  end

  def self.down
    remove_column :offers, :reward_value
  end
end
