class AddTapjoySponsored < ActiveRecord::Migration
  def self.up
    add_column :offers, :tapjoy_sponsored, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :offers, :tapjoy_sponsored
  end
end
