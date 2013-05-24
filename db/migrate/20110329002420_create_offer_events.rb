class CreateOfferEvents < ActiveRecord::Migration
  def self.up
    create_table :offer_events, :id => false do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :offer_id, 'char(36) binary', :null => false
      t.integer :daily_budget
      t.boolean :user_enabled
      t.boolean :change_daily_budget, :null => false, :default => false
      t.boolean :change_user_enabled, :null => false, :default => false
      t.timestamp :scheduled_for, :null => false
      t.timestamp :ran_at
      t.timestamp :disabled_at
      t.timestamps
    end

    add_index :offer_events, :id, :unique => true
    add_index :offer_events, :offer_id
  end

  def self.down
    drop_table :offer_events
  end
end
