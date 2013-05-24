class CreatePayoutInfos < ActiveRecord::Migration
  def self.up
    create_table :payout_infos, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :partner_id, 'char(36) binary', :null => false
      t.string :tax_country
      t.string :account_type
      t.string :billing_name
      t.text :tax_id
      t.string :beneficiary_name
      t.string :company_name
      t.string :address_1
      t.string :address_2
      t.string :address_city
      t.string :address_state
      t.string :address_postal_code
      t.string :address_country
      t.text :bank_name
      t.text :bank_address
      t.text :bank_account_number
      t.text :bank_routing_number
      t.timestamps
    end

    add_index :payout_infos, :id, :unique => true
    add_index :payout_infos, :partner_id
  end

  def self.down
    drop_table :payout_infos
  end
end
