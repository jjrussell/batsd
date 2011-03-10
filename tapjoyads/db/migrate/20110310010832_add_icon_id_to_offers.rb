class AddIconIdToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :icon_id_override, 'char(36) binary'
  end

  def self.down
    remove_column :offers, :icon_id_override
  end
end
