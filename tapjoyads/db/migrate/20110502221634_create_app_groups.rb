class CreateAppGroups < ActiveRecord::Migration
  def self.up
    create_table :app_groups, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.integer :conversion_rate, :default => 0, :null => false
      t.integer :bid, :default => 0, :null => false
      t.integer :price, :default => 0, :null => false
      t.integer :avg_revenue, :default => 0, :null => false
      t.integer :random, :default => 0, :null => false
      t.integer :over_threshold, :default => 0, :null => false
      t.string :name
      t.timestamps
    end
    
    add_index :app_groups, :id, :unique => true
    add_column :apps, :app_group_id, 'char(36) binary', :null => false
    add_index :apps, :app_group_id
    
    app_group = AppGroup.create(:name => 'default', :conversion_rate => 1, :bid => 1, :price => -1, :avg_revenue => 5, :random => 1, :over_threshold => 6)
    App.connection.execute("UPDATE apps SET app_group_id = '#{app_group.id}'")
  end

  def self.down
    remove_column :apps, :app_group_id
    drop_table :app_groups
  end
end
