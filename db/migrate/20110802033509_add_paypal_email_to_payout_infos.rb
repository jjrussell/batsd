class AddPaypalEmailToPayoutInfos < ActiveRecord::Migration
  def self.up
    add_column :payout_infos, :paypal_email, :string
  end

  def self.down
    remove_column :payout_infos, :paypal_email
  end
end
