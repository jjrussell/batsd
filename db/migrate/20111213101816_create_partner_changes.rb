class CreatePartnerChanges < ActiveRecord::Migration
  def self.up
    create_table :partner_changes, :id => false do |t|
      t.guid :id, :null => false
      t.guid :item_id, :null => false
      t.string :item_type, :null => false
      t.guid :source_partner_id, :null => false
      t.guid :destination_partner_id, :null => false
      t.datetime :scheduled_for
      t.datetime :completed_at
      t.timestamps
    end

    add_index :partner_changes, :id, :unique => true
    add_index :partner_changes, :item_id
    add_index :partner_changes, [:item_type, :item_id]
    add_index :partner_changes, :source_partner_id
    add_index :partner_changes, :destination_partner_id
    add_index :partner_changes, [:scheduled_for, :completed_at]
  end

  def self.down
    drop_table :partner_changes
  end
end
