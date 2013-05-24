class AddAutoUpdateIconToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :auto_update_icon, :boolean, :default => false
  end

  def self.down
    remove_column :offers, :auto_update_icon
  end
end
