class OfferCompletedController < ApplicationController

  before_filter :setup

  def index
    complete_conversion
  end

  def boku
    @source = 'boku'
    @trx_id = params['trx-id']
    @adjusted_payment = params['reference-receivable-net'].to_i
    params[:click_key] = params[:param]
    if request.query_parameters[:action] == 'billingresult' && params['result-code'] == '0'
      complete_conversion
    else
      @error_message = "unexpected boku callback"
      notify_and_render_error(false)
    end
  end

  def gambit
    @source = 'gambit'
    params[:click_key] = params[:subid1]
    complete_conversion
  end

  def paypal
    # paypal_verifier_url = "https://www.paypal.com/cgi-bin/webscr"
    # paypal_verifier_data = "cmd=_notify-validate&#{request.raw_post}"
    # paypal_response = Downloader.post(paypal_verifier_url, paypal_verifier_data, :timeout => 30)

    @source = 'paypal'
    @adjusted_payment = ((params[:payment_gross].to_f - params[:payment_fee].to_f) * 100).to_i
    params[:click_key] = params[:custom]
    if params[:payment_status] == 'Completed' && params[:receiver_email] == 'paypal@tapjoy.com'
      complete_conversion
    else
      @error_message = "unexpected paypal callback"
      notify_and_render_error(false)
    end
  end

  def socialvibe
    @source = 'socialvibe'
    complete_conversion
  end

private

  def setup
    @now = Time.zone.now
  end

  def complete_conversion
    if params[:click_key].blank?
      @error_message = "click_key required"
      notify_and_render_error(false) and return
    end

    click = Click.new(:key => params[:click_key])

    if click.is_new
      @error_message = "click not found (#{click.key})"
      notify_and_render_error(true) and return
    elsif click.installed_at.present?
      @error_message = "click has already converted (#{click.key})"
      notify_and_render_error(false) and return
    end

    offer = Offer.find_in_cache(click.offer_id)
    unless verify_records([ offer ], { :render_missing_text => false })
      @error_message = "record not found (#{click.key})"
      notify_and_render_error(true) and return
    end

    if offer.has_variable_payment?
      if params[:payment].blank?
        @error_message = "payment required (#{click.key})"
        notify_and_render_error(false) and return
      end

      @adjusted_payment = params[:payment].to_i
      if @adjusted_payment < offer.payment_range_low || @adjusted_payment > offer.payment_range_high
        @error_message = "payment (#{@adjusted_payment}) out of range (#{offer.payment_range_low}-#{offer.payment_range_high}) for click (#{click.key})"
        notify_and_render_error(false) and return
      end
    end

    if @adjusted_payment.present?
      if @adjusted_payment > 0
        currency = Currency.find_in_cache(click.currency_id)
        unless verify_records([ currency ], { :render_missing_text => false })
          @error_message = "record not found (#{click.key})"
          notify_and_render_error(true) and return
        end
        offer.payment = @adjusted_payment

        click.advertiser_amount = currency.get_advertiser_amount(offer)
        click.publisher_amount  = currency.get_publisher_amount(offer)
        click.currency_reward   = currency.get_reward_amount(offer)
        click.tapjoy_amount     = currency.get_tapjoy_amount(offer)
        click.save
      else
        @error_message = "invalid adjusted payment (#{@adjusted_payment}) for click (#{click.key})"
        notify_and_render_error(false) and return
      end
    end

    device = Device.new(:key => click.udid)
    if device.has_app?(click.advertiser_app_id) && (!offer.multi_complete? || offer.frequency_capping_reject?(device))
      click.block_reason = "AlreadyCompleted"
      click.save
      @error_message = "offer has already been completed by this device for click {#{click.key}}"
      notify_and_render_error(false)
    else
      device.set_last_run_time!(click.advertiser_app_id)
      message = { :click => click.serialize(:attributes_only => true), :install_timestamp => @now.to_f.to_s }.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
      render_success
    end
  end

  def render_success
    case @source
    when 'gambit'
      render :text => 'OK'
    when 'boku'
      render :template => 'layouts/boku'
    when 'socialvibe'
      render :text => '1'
    else
      render :template => 'layouts/success'
    end
  end

  def notify_and_render_error(retry_if_supported)
    Notifier.alert_new_relic(GenericOfferCallbackError, @error_message, request, params)
    case @source
    when 'gambit'
      render :text => (retry_if_supported ? 'ERROR:RESEND' : 'ERROR:FATAL')
    when 'boku'
      render :template => 'layouts/boku'
    when 'paypal'
      render :template => 'layouts/error'
    when 'socialvibe'
      render :text => (retry_if_supported ? '0' : '3')
    else
      render :template => 'layouts/error', :status => (retry_if_supported ? 404 : 403)
    end
  end

end
