class AddSignatureToPayoutInfos < ActiveRecord::Migration
  def self.up
    add_column :payout_infos, :signature, :string
  end

  def self.down
    remove_column :payout_infos, :signature
  end
end
