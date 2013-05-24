class ChangePayPerClickToIntForOffers < ActiveRecord::Migration
  def self.up
    change_column :offers, :pay_per_click, :integer, :null => false, :default => Offer::PAY_PER_CLICK_TYPES[:non_ppc]
  end

  def self.down
    change_column :offers, :pay_per_click, :boolean, :default => false
  end
end
