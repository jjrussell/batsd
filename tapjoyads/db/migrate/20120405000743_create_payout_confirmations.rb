class CreatePayoutConfirmations < ActiveRecord::Migration
  def self.up
    create_table :payout_confirmations, :id => false do |t|
      t.guid   :id, :null => false
      t.guid   :partner_id, :null => false
      t.string :type, :null => false
      t.boolean :confirmed, :null => false, :default => false
      t.timestamps
    end

    add_index :payout_confirmations, [:partner_id, :type], :name => 'index_payout_confirmation_partner_type', :unique => true
    add_index :payout_confirmations, [:partner_id], :name => 'index_payout_confirmation_partner', :unique => false
  end

  def self.down
    drop_table :payout_confirmations
  end
end
