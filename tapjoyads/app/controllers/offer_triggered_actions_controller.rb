class OfferTriggeredActionsController < ApplicationController
  include Facebooker2::Rails::Controller
  prepend_before_filter :decrypt_data_param
  before_filter :lookup_device, :setup

  layout 'instructions', :only => [ :load_app, :fb_login, :fb_visit ]

  def load_app
    @protocol_handler_url = @offer.generic_offer_protocol_handler
  end

  def fb_login
    @redirect_url = "#{WEBSITE_URL}/gamer/create_account_for_offer?tapjoy_device_id=#{get_device_key}"
  end

  def fb_visit
  end

  private

  def setup
    return unless verify_params([ :data, :id, :publisher_app_id ]) && verify_records(get_device_key)

    @offer = Offer.find_in_cache params[:id]
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    return unless verify_records([ @currency, @offer ])

    @impression_tracking_urls = @offer.impression_tracking_urls
    @click_tracking_urls = @offer.click_tracking_urls
    @conversion_tracking_urls = @offer.conversion_tracking_urls

    complete_action_data = {
      :tapjoy_device_id      => get_device_key,
      :udid                  => params[:udid],
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => params[:click_key],
      :device_click_ip       => params[:device_click_ip],
      :itunes_link_affiliate => params[:itunes_link_affiliate],
      :library_version       => params[:library_version],
      :os_version            => params[:os_version]
    }

    if @offer.has_instructions? && @offer.pay_per_click?(:ppc_on_instruction)
      @complete_instruction_url = @offer.instruction_action_url(complete_action_data.merge(:viewed_at => Time.zone.now.to_f))
    else
      @complete_instruction_url = @offer.complete_action_url(complete_action_data)
    end
  end

end
