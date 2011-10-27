class RemoveOldTargetingColumns < ActiveRecord::Migration
  def self.up
    remove_column :offers, :cities
    remove_column :offers, :postal_codes
    change_column :offers, :dma_codes, :text, :null => false, :default => ''
  end

  def self.down
    add_column :offers, :cities, :text
    add_column :offers, :postal_codes, :text
  end
end
