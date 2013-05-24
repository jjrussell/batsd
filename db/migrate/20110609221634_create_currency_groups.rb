class CreateCurrencyGroups < ActiveRecord::Migration
  def self.up
    create_table :currency_groups, :id => false do |t|
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

    add_index :currency_groups, :id, :unique => true
    add_column :currencies, :currency_group_id, 'char(36) binary', :null => false
    add_index :currencies, :currency_group_id
  end

  def self.down
    remove_column :currencies, :currency_group_id
    drop_table :currencies_groups
  end
end
