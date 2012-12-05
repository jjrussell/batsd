class CouponInstructionsController < ApplicationController
  prepend_before_filter :decrypt_data_param
  before_filter :setup
  before_filter :lookup_device, :only => [ :create ]

  def new
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    return unless verify_records([ @publisher_app ])
  end

  def create
    return unless verify_params([ :email_address ]) && verify_records(get_device_key)
    @device = find_or_create_device
    return unless verify_records([ @device ])

    unless params[:email_address] =~ Authlogic::Regex.email
      redirect_to(new_coupon_instruction_path(:data => params[:data]), :notice => 'Input a valid email address.') and return
    end

    if @device.pending_coupons.include?(@offer.id)
      redirect_to(new_coupon_instruction_path(:data => params[:data]), :notice => 'Coupon has already been requested.') and return
    end

    complete_action_url = @offer.complete_action_url({
      :udid                  => params[:udid],
      :tapjoy_device_id      => get_device_key,
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => params[:click_key],
      :device_click_ip       => params[:device_click_ip],
      :itunes_link_affiliate => params[:itunes_link_affiliate],
      :library_version       => params[:library_version],
      :os_version            => params[:os_version]
    })

    send_email
    set_device_with_pending_coupon
    redirect_to(complete_action_url)
  end

  private

  def setup
    verify_params([ :data, :id, :publisher_app_id ])
    @offer = Offer.find_in_cache(params[:id])
    @coupon = Coupon.find_in_cache(@offer.item_id) if @offer
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id]) if @coupon
    verify_records([ @currency, @offer, @coupon ])
  end

  def send_email
    message = {
      :email_address => params[:email_address],
      :coupon_id     => @coupon.id,
      :click_key     => params[:click_key]
    }.to_json
    Sqs.send_message(QueueNames::SEND_COUPON_EMAILS, message)
  end

  def set_device_with_pending_coupon
    @device.set_pending_coupon(@offer.id)
  end

end
