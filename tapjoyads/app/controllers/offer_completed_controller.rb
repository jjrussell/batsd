class OfferCompletedController < ApplicationController
  
  before_filter :setup
  
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
      
      currency = Currency.find_in_cache(click.currency_id)
      offer.payment = payment
      
      click.advertiser_amount = currency.get_advertiser_amount(offer)
      click.publisher_amount  = currency.get_publisher_amount(offer)
      click.currency_reward   = currency.get_reward_amount(offer)
      click.tapjoy_amount     = currency.get_tapjoy_amount(offer)
      click.save
    end
    
    device = Device.new(:key => click.udid)
    device.set_app_ran(click.advertiser_app_id, params)
    device.save
    
    message = { :click => click.serialize(:attributes_only => true), :install_timestamp => now.to_f.to_s }.to_json
    Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    
    render_success
  end
  
private
  
  def setup
    @source = nil
    
    if params[:source] == 'gambit'
      @source = 'gambit'
      params[:click_key] = params[:subid1]
    elsif params[:source] == 'boku'
      @source = 'boku'
      @trx_id = params['trx-id']
      if request.query_parameters[:action] == 'billingresult' && params['result-code'] == '0' && params[:param].present?
        params[:click_key] = params[:param]
      else
        @error_message = "unexpected boku callback"
        notify_and_render_error and return
      end
    end
  end
  
  def render_success
    if @source == 'gambit'
      render :text => 'OK'
    elsif @source == 'boku'
      render(:template => 'layouts/boku')
    else
      render(:template => 'layouts/success')
    end
  end
  
  def notify_and_render_error
    Notifier.alert_new_relic(GenericOfferCallbackError, @error_message, request, params)
    if @source == 'gambit'
      render :text => 'ERROR:FATAL'
    elsif @source == 'boku'
      render(:template => 'layouts/boku')
    else
      render(:template => 'layouts/error', :status => 403)
    end
  end
  
end
