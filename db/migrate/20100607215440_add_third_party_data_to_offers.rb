class AddThirdPartyDataToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :third_party_data, :string
  end

  def self.down
    remove_column :offers, :third_party_data
  end
end
