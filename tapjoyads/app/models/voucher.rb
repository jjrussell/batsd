class Voucher < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  belongs_to :coupon, :foreign_key => :coupon_id

  validates_presence_of :ref_id, :coupon_id, :redemption_code, :acquired_at, :expires_at, :barcode_url

  def self.request_voucher(coupon, email, click_key)
    voucher = JSON.parse(%x{curl -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-ADILITY-API-KEY: #{ADILITY_KEY}" "#{ADILITY_API_URL}/#{coupon.provider_id}/vouchers" -d '{"voucher": {}}'})["voucher"]
    find(:all, :conditions => { :ref_id => voucher["id"]}).present? ? [] : create_new_voucher(voucher, coupon.id, email, click_key)
  end

  def self.create_new_voucher(voucher, coupon_id, email, click_key)
    Voucher.create!( :ref_id          => voucher.delete("id"),
                     :coupon_id       => coupon_id,
                     :redemption_code => voucher.delete("redemption_code"),
                     :acquired_at     => (Date.strptime voucher.delete("acquired_at"), '%Y-%m-%d'),
                     :expires_at      => (Date.strptime voucher.delete("expires_at"), '%Y-%m-%d'),
                     :barcode_url     => voucher.delete("barcode_url"),
                     :email_address   => email,
                     :click_key       => click_key
                   )
  end
end
