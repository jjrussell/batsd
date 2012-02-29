class AddActiveGamerCountToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :active_gamer_count, :integer, :default => 0
  end

  def self.down
    remove_column :apps, :active_gamer_count
  end
end
