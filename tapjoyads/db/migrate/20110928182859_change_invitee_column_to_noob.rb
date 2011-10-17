class ChangeInviteeColumnToNoob < ActiveRecord::Migration
  def self.up
    rename_column :invitations, :invitee_id, :noob_id
  end

  def self.down
    rename_column :invitations, :noob_id, :invitee_id
  end
end
