class OfferCompletedController < ApplicationController
  
  def index
    if params[:click_key].blank?
      @error_message = "click_key required"
      notify_and_render_error and return
    end
    
    now = Time.zone.now
    click = Click.new(:key => params[:click_key])
    
    if click.is_new
      @error_message = "click not found (#{click.key})"
      notify_and_render_error and return
    elsif click.installed_at.present?
      @error_message = "click has already converted (#{click.key})"
      notify_and_render_error and return
    elsif click.clicked_at < (now - 2.days)
      @error_message = "click too old (#{click.key})"
      notify_and_render_error and return
    end
    
    offer = Offer.find_in_cache(click.offer_id)
    
    if offer.has_variable_payment?
      if params[:payment].blank?
        @error_message = "payment required (#{click.key})"
        notify_and_render_error and return
      end
      
      payment = params[:payment].to_i
      if payment < offer.payment_range_low || payment > offer.payment_range_high
        @error_message = "payment (#{payment}) out of range (#{offer.payment_range_low}-#{offer.payment_range_high}) for click (#{click.key})"
        notify_and_render_error and return
      end
      
      currency = Currency.find_in_cache_by_app_id(click.publisher_app_id)
      offer.payment = payment
      
      click.advertiser_amount = currency.get_advertiser_amount(offer)
      click.publisher_amount  = currency.get_publisher_amount(offer)
      click.currency_reward   = currency.get_reward_amount(offer)
      click.tapjoy_amount     = currency.get_tapjoy_amount(offer)
      click.save
    end
    
    device_app_list = DeviceAppList.new(:key => click.udid)
    device_app_list.set_app_ran(click.advertiser_app_id)
    device_app_list.save
    
    message = { :click => click.serialize(:attributes_only => true), :install_timestamp => now.to_f.to_s }.to_json
    Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    
    render(:template => 'layouts/success')
  end
  
private
  
  def notify_and_render_error
    Notifier.alert_new_relic(GenericOfferCallbackError, @error_message, request, params)
    render(:template => 'layouts/error', :status => 500)
  end
  
end
