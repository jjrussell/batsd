class AddDailyCapTypeToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :daily_cap_type, :string
  end

  def self.down
    remove_column :offers, :daily_cap_type
  end
end
