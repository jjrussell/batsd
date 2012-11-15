class CreateConversionRates < ActiveRecord::Migration
  def self.up
    create_table :conversion_rates, :id => false do |t|
      t.guid :id,                         :null => false
      t.integer :rate,                    :null => false
      t.integer :minimum_offerwall_bid,   :null => false
      t.guid :currency_id,                :null => false
    end

    add_index :conversion_rates, :id, :unique => true
    add_index :conversion_rates, :currency_id
    add_index :conversion_rates, [:currency_id, :rate], :unique => true
    add_index :conversion_rates, [:currency_id, :minimum_offerwall_bid], :unique => true
  end

  def self.down
    drop_table :conversion_rates
  end
end
