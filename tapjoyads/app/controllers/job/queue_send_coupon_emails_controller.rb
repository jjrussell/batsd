class Job::QueueSendCouponEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_COUPON_EMAILS
  end

  private

  def on_message(message)
    data = JSON.load(message.body)
    coupon = Coupon.find_in_cache(data["coupon_id"])
    voucher = Voucher.request_voucher(coupon, data["email_address"], data["click_key"])
    TapjoyMailer.email_coupon_offer(voucher.email_address, voucher.barcode_url, voucher.expires_at,
                                    voucher.redemption_code, coupon.description, coupon.name, coupon.advertiser_name) unless voucher.blank?
  end

end
