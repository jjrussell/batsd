class CreateCurrencies < ActiveRecord::Migration
  def self.up
    create_table :currencies, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :app_id, 'char(36) binary', :null => false
      t.string :name
      t.integer :conversion_rate, :null => false, :default => 100
      t.integer :initial_balance, :null => false, :default => 0
      t.boolean :has_virtual_goods, :null => false, :default => false
      t.boolean :only_free_offers, :null => false, :default => false
      t.boolean :send_offer_data, :null => false, :default => false
      t.string :secret_key
      t.string :callback_url
      t.decimal :offers_money_share, :precision => 8, :scale => 6, :null => false, :default => 0.85
      t.decimal :installs_money_share, :precision => 8, :scale => 6, :null => false, :default => 0.7
      t.text :disabled_offers, :null => false, :default => ''
      t.text :test_devices, :null => false, :default => ''
      t.timestamps
    end

    add_index :currencies, :id, :unique => true
    add_index :currencies, :app_id
  end

  def self.down
    drop_table :currencies
  end
end
