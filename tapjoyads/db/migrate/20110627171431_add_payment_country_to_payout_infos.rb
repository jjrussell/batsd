class AddPaymentCountryToPayoutInfos < ActiveRecord::Migration
  def self.up
    add_column :payout_infos, :payment_country, :string
  end

  def self.down
    remove_column :payout_infos, :payment_country
  end
end
