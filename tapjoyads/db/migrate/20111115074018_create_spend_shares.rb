class CreateSpendShares < ActiveRecord::Migration
  def self.up
    create_table :spend_shares, :id => false do |t|
      t.guid :id, :null => false
      t.float :ratio, :null => false
      t.date :effective_on, :null => false
      t.timestamps
    end
    add_index :spend_shares, :id, :unique => true
    add_index :spend_shares, :effective_on, :unique => true
  end

  def self.down
    drop_table :spend_share_ratios
  end
end
