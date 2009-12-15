class SubmitClickController < ApplicationController
  include RewardHelper
  
  def store
    return unless verify_params([:advertiser_app_id, :udid, :publisher_app_id, :publisher_user_record_id])
    
    now = Time.now.utc
    
    ##
    # store the value of an install in this table
    # so the user gets the reward they think they earned
    app = App.new(params[:advertiser_app_id])
    advertiser_amount = app.get('payment_for_install').to_i
    
    if advertiser_amount <= 0
      if app.get('price').to_i <= 0
        advertiser_amount = 25
      else
        advertiser_amount = app.get('price').to_i / 2
      end
    end
    
    ##
    # store how much currency the user earns for this install    
    currency = Currency.new(params[:publisher_app_id])

    values = calculate_install_payouts(:currency => currency, :advertiser_app => app)
    
    ##
    # each attribute that starts with publisher.<id> has a . separated value
    # the left of the . is when the click happened.  the right of the . is the publisher user record
    # so when the app is installed, we look at the timestamp to determine where the reward goes
    click = StoreClick.new("#{params[:udid]}.#{params[:advertiser_app_id]}", {:load => false})
    click.put("click_date", "#{now.to_f.to_s}")
    click.put("publisher_app_id",params[:publisher_app_id])
    click.put("publisher_user_record_id", params[:publisher_user_record_id])
    click.put("advertiser_app_id", params[:advertiser_app_id])
    click.put('advertiser_amount', values[:advertiser_amount])
    click.put('publisher_amount', values[:publisher_amount])
    click.put('currency_reward', values[:currency_reward])
    click.put('tapjoy_amount', values[:tapjoy_amount])
    click.put('offerpal_amount', values[:offerpal_amount])
    click.save
    
    if params[:redirect] == "1"
      app = App.new(params[:advertiser_app_id])
      redirect_to app.get('store_url')
    else
      #render :template => 'layouts/success'
      render :text => values.to_s
    end
  end
  
  def offer
    return unless verify_params([:app_id, :udid, :offer_id, :publisher_user_record_id])
    
    now = Time.now.utc
    
    click = OfferClick.new(UUIDTools::UUID.random_create.to_s)
    click.put("click_date", "#{now.to_f.to_s}")
    click.put('offer_id', params[:offer_id])
    click.put('app_id', params[:app_id])
    click.put('udid', params[:udid])
    click.put('record_id', params[:publisher_user_record_id])
    click.put('source', 'app')
    click.put('ip_address', request.remote_ip)
    click.save
        
    render :template => 'layouts/success'
  end
  
  def ad
    return unless verify_params([:campaign_id, :app_id, :udid])

    web_request = WebRequest.new('adclick')
    web_request.put('campaign_id', params[:campaign_id])
    web_request.put('app_id', params[:app_id])
    web_request.put('udid', params[:udid])
    web_request.put('ip_address', request.remote_ip)
    
    web_request.save

    render :template => 'layouts/success'
  end
end
