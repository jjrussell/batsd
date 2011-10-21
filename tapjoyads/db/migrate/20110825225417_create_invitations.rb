class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations, :id => false do |t|
      t.guid    :id, :null => false
      t.guid    :gamer_id, :null => false
      t.guid    :invitee_id, :null => true
      t.string  :external_info, :null => false
      t.integer  :channel, :null => false
      t.integer  :status, :default => 0
      t.timestamps
    end

    add_index :invitations, :id, :unique => true
    add_index :invitations, :gamer_id
    add_index :invitations, :external_info
  end

  def self.down
    drop_table :invitations
  end
end
