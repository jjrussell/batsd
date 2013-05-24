class AddApsalarSharingToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :apsalar_sharing_adv, :boolean, :null => false, :default => false
    add_column :partners, :apsalar_sharing_pub, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :partners, :apsalar_sharing_adv
    remove_column :partners, :apsalar_sharing_pub
  end
end

