class AddApsalarSharingToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :apsalar_sharing, :boolean
  end

  def self.down
    remove_column :partners, :apsalar_sharing
  end
end

