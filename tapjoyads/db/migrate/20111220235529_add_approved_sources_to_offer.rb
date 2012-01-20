class AddApprovedSourcesToOffer < ActiveRecord::Migration
  def self.up
    add_column :offers, :approved_sources, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :offers, :approved_sources
  end
end
