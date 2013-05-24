class AddSelfPromoteOnlyToApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :self_promote_only, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :apps, :self_promote_only
  end
end
