class AddPayoutMethodToPayoutInfos < ActiveRecord::Migration
  def self.up
    add_column :payout_infos, :payout_method, :string
  end

  def self.down
    remove_column :payout_infos, :payout_method
  end
end
