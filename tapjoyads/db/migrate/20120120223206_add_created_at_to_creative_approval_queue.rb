class AddCreatedAtToCreativeApprovalQueue < ActiveRecord::Migration
  def self.up
    add_column :creative_approval_queue, :created_at, :datetime
  end

  def self.down
    remove_column :creative_approval_queue, :created_at
  end
end
