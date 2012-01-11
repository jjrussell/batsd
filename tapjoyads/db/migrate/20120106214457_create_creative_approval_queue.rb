class CreateCreativeApprovalQueue < ActiveRecord::Migration
  def self.up
    create_table :creative_approval_queue do |t|
      t.guid :offer_id, :null => false
      t.integer :user_id
      t.text :size
    end
  end

  def self.down
    drop_table :creative_approval_queue
  end
end
