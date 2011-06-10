class AddDoingBusinessAsToPayoutInfos < ActiveRecord::Migration
  def self.up
    add_column :payout_infos, :doing_business_as, :string
  end

  def self.down
    remove_column :payout_infos, :doing_business_as
  end
end
