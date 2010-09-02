class ChangeOffersColumns < ActiveRecord::Migration
  def self.up
    change_column :offers, :daily_budget, :integer, :null => false, :default => 0
    change_column :offers, :overall_budget, :integer, :null => false, :default => 0
    change_column :offers, :countries, :text, :null => false, :default => ''
    change_column :offers, :cities, :text, :null => false, :default => ''
    change_column :offers, :postal_codes, :text, :null => false, :default => ''
    change_column :offers, :device_types, :text, :null => false
  end

  def self.down
    # no down
  end
end
