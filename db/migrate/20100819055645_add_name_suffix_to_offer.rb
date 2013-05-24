class AddNameSuffixToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :name_suffix, :string, :default => ''
  end

  def self.down
    remove_column :offers, :name_suffix
  end
end
