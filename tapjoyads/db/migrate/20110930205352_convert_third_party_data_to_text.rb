class ConvertThirdPartyDataToText < ActiveRecord::Migration
  def self.up
    change_column :offers, :third_party_data, :text
  end

  def self.down
    change_column :offers, :third_party_data, :string
  end
end
