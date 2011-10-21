class CreateRankBoosts < ActiveRecord::Migration
  def self.up
    create_table :rank_boosts, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :offer_id, 'char(36) binary', :null => false
      t.timestamp :start_time, :null => false
      t.timestamp :end_time, :null => false
      t.integer :amount, :null => false
      t.timestamps
    end

    add_index :rank_boosts, :id, :unique => true
    add_index :rank_boosts, :offer_id
  end

  def self.down
    drop_table :rank_boosts
  end
end
