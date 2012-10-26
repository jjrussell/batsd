class Voucher < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "vouchers"

  belongs_to :coupon, :foreign_key => :coupon_id

  self.domain_name = 'vouchers'

  self.sdb_attr :coupon_id
  self.sdb_attr :redemption_code
  self.sdb_attr :acquired_at, :type => :time
  self.sdb_attr :expires_at, :type => :time
  self.sdb_attr :barcode_url
  self.sdb_attr :email_address
  self.sdb_attr :click_key
  self.sdb_attr :completed, :type => :bool

  def self.request_voucher(coupon, email, click_key)
    voucher = JSON.parse(%x{curl -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "X-ADILITY-API-KEY: #{ADILITY_KEY}" "#{ADILITY_API_URL}/#{coupon.provider_id}/vouchers" -d '{"voucher": {}}'})["voucher"]
    Voucher.find(voucher["id"]).present? ? [] : create_new_voucher(voucher, coupon.id, email, click_key)
  end

  private

  def self.create_new_voucher(voucher_obj, coupon_id, email, click_key)
    voucher                 = Voucher.new(:key => voucher_obj.delete("id"))
    voucher.coupon_id       = coupon_id
    voucher.redemption_code = voucher_obj.delete("redemption_code")
    voucher.acquired_at     = Time.zone.parse voucher_obj.delete("acquired_at")
    voucher.expires_at      = Time.zone.parse voucher_obj.delete("expires_at")
    voucher.barcode_url     = voucher_obj.delete("barcode_url")
    voucher.email_address   = email
    voucher.click_key       = click_key
    voucher.completed       = false
    voucher.save
    voucher
  end
end
