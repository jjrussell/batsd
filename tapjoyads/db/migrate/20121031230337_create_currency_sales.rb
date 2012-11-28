class CreateCurrencySales < ActiveRecord::Migration
  def self.up
    create_table :currency_sales, :id => false do |t|
      t.guid      :id,                :null => false
      t.timestamp :start_time,        :null => false
      t.timestamp :end_time,          :null => false
      t.float     :multiplier,        :null => false
      t.guid      :currency_id,       :null => false
      t.boolean   :message_enabled,   :null => false, :default => false
      t.text      :message
      t.timestamps
    end

    add_index :currency_sales, :id, :unique => true
    add_index :currency_sales, :currency_id
  end

  def self.down
    drop_table :currency_sales
  end
end
