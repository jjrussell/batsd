class AddSdklessToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :sdkless, :boolean, :default => false
  end

  def self.down
    remove_column :offers, :sdkless
  end
end
