class CreatePayoutFreezes < ActiveRecord::Migration
  def self.up
    create_table :payout_freezes, :id => false do |t|
      t.guid :id, :null => false
      t.boolean :enabled, :null => false, :default => true
      t.datetime :enabled_at
      t.datetime :disabled_at
      t.string :enabled_by
      t.string :disabled_by
      t.timestamps
    end

    add_index :payout_freezes, :id, :unique => true
    add_index :payout_freezes, :enabled
  end

  def self.down
    drop_table :payout_freezes
  end
end
