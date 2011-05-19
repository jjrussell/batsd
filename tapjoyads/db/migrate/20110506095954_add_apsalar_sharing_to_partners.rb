class AddApsalarSharingToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :apsalar_sharing, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :partners, :apsalar_sharing
  end
end

