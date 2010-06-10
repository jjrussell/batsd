class MoveSelfPromoteOnlyToOffers < ActiveRecord::Migration
  def self.up
    remove_column :apps, :self_promote_only
    add_column :offers, :self_promote_only, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :offers, :self_promote_only
    add_column :apps, :self_promote_only, :boolean, :null => false, :default => false
  end
end
