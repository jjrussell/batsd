class CreateApprovals < ActiveRecord::Migration
  def self.up
    create_table :approvals do |t|
      t.string   :item_type, :null => false
      t.guid     :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :state,     :null => false, :default => 'pending'
      
      t.guid     :owner_id
      
      t.text     :object
      t.text     :reason

      t.timestamps
    end

    add_index :approvals, [:state, :event]
    add_index :approvals, [:item_type, :item_id]
    
    add_index :approvals, [:owner_id]
    
  end

  def self.down
    remove_index :approvals, [:state, :event]
    remove_index :approvals, [:item_type, :item_id]
    
    remove_index :approvals, [:owner_id]
    
    drop_table :approvals
  end
end
