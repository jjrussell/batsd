require 'base64'

class ImportMssqlController < ApplicationController
  include TimeLogHelper
  include MemcachedHelper
  
  protect_from_forgery :except => [:publisher_ad, :app, :campaign]
  
  def currency
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

    if (not params[:app_id])
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'connect')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end

    app_id = params[:app_id]

    app = Currency.new(app_id)
    
    app.put('currency_name',params[:currency_name])
    app.put('conversion_rate', params[:conversion_rate])
    app.put('initial_balance', params[:initial_balance])
    app.put('virtual_goods_currency', params[:virtual_goods_currency])
    app.put('secret_key', params[:secret_key]) if params[:secret_key] != ''
    app.put('callback_url', params[:callback_url])
    app.put('cs_callback_url', params[:cs_callback_url])
    app.put('offers_money_share', params[:offers_money_share])
    app.put('installs_money_share', params[:installs_money_share])
    app.put('disabled_offers', params[:disabled_offers])
    app.put('disabled_apps', params[:disabled_apps]) 
    app.put('show_rating_offer', params[:show_rating_offer])

    app.save

    respond_to do |f|
      f.xml {render(:text => xml)}
    end    
  end
  
  def publisher_ad
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

    if ( (not params[:ad_id]) || (not params[:partner_id]) )
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'connect')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
    ad_id = params[:ad_id]
  
    ad = PublisherAd.new(ad_id)
    unless ad.get('next_run_time')
        next_run_time = (Time.now.utc).to_f.to_s
        ad.put('next_run_time', next_run_time)     
        ad.put('interval_update_time','60')
    end
    ad.put('partner_id', params[:partner_id])
    ad.put('app_id_to_advertise', params[:app_id_to_advertise]) if params[:app_id_to_advertise]
    ad.put('app_id_restricted', params[:app_id_restricted]) if params[:app_id_restricted]
    ad.put('name', params[:name])
    ad.put('description', params[:description])
    ad.put('url', params[:url])
    ad.put('open_in', params[:open_in])
    ad.put('max_daily_impressions', params[:max_daily_impressions]) if params[:max_daily_impressions]
    ad.put('max_total_impressions', params[:max_total_impressions]) if params[:max_total_impressions]
    ad.put('max_impressions_per_device', params[:max_impressions_per_device]) if params[:max_impressions_per_device]
    ad.put('cpc', params[:cpc]) if params[:cpc]
    ad.put('cpa', params[:cpa]) if params[:cpa]    
    ad.put('cpm', params[:cpm]) if params[:cpm]
    
    ad.save
  
    # Keep it non-multithreaded for now.
    # TODO: determine what steps are needed to make S3Object threadsafe.
    #Thread.new do
      #store an image in s3
      time_log("Stored in s3") do
        AWS::S3::S3Object.store "raw." + ad_id, params[:image], 'publisher-ads'
        AWS::S3::S3Object.store "base64." + ad_id, Base64.b64encode(params[:image]), 'publisher-ads'
      end
    #end
  
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
    
  end
  
  def app
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

    if (not params[:app_id])
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'connect')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end

    app_id = params[:app_id]

    app = App.new(app_id)
    unless app.get('next_run_time')
        next_run_time = (Time.now.utc).to_f.to_s
        app.put('next_run_time', next_run_time)     
        app.put('interval_update_time','60')
    end

    unless app.get('next_ad_optimization_time')
        next_run_time = (Time.now.utc).to_f.to_s
        app.put('next_ad_optimization_time', next_run_time)     
        app.put('ad_optimization_interval_update_time','60')
    end

    app.put('name',params[:name])
    app.put('payment_for_install', params[:payment_for_install])
    app.put('rewarded_installs_ordinal', params[:rewarded_installs_ordinal])
    app.put('install_tracking', params[:install_tracking])
    app.put('store_url', params[:store_url])
    app.put('partner_id', params[:partner_id])
    app.put('os', params[:os])
    app.put('launched', params[:launched])
    app.put('status', params[:status])
    app.put('color', params[:color])
    app.put('price', params[:price]) 
    app.put('description', params[:description], {:cgi_escape => true}) if params[:description]
    app.put('has_location', params[:has_location])
    app.put('balance', params[:balance])
    app.put('description_1',' ') if app.get('description_1')
    app.put('description_2',' ') if app.get('description_2')
    app.put('description_3',' ') if app.get('description_3')

    app.save

    time_log("Stored in s3") do
      AWS::S3::S3Object.store app_id, params[:icon], 'app-icons'
      save_to_cache("icon.s3.#{app_id.hash}", Base64.encode64(params[:icon]))
      AWS::S3::S3Object.store app_id, params[:screenshot], 'app-screenshots'
    end

    respond_to do |f|
      f.xml {render(:text => xml)}
    end

  end
    
  def campaign
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

    if ( (not params[:campaign_id]) || (not params[:app_id]) )
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'connect')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
    campaign_id = params[:campaign_id]
  
    campaign = Campaign.new(campaign_id)
    campaign.put('app_id', params[:app_id])
    campaign.put('ad_space', '1')
    
    unless campaign.get('next_run_time')
        next_run_time = (Time.now.utc).to_f.to_s
        campaign.put('next_run_time', next_run_time)     
        campaign.put('interval_update_time','60')
    end
    
    unless campaign.get('next_ecpm_update')
        next_run_time = (Time.now.utc).to_f.to_s
        campaign.put('next_ecpm_update', next_run_time)     
        campaign.put('ecpm_interval_update_time','3660') #update ecpm once an hour at most
    end


    campaign.put('network_id', params[:network_id])
    campaign.put('network_name', params[:network_name])
    campaign.put('name', params[:name])
    campaign.put('description', params[:description])
    campaign.put('ecpm', params[:ecpm])
    campaign.put('status', params[:status])
    campaign.put('call_ad_shown', params[:call_ad_shown])
    campaign.put('format', params[:format])
    campaign.put('custom_ad', params[:custom_ad])
    campaign.put('test_percent', params[:test_percent])
    campaign.put('bar', params[:bar])
    campaign.put('ad_id', params[:ad_id])
    campaign.put('id1', params[:id1])
    campaign.put('id2', params[:id2])   
    campaign.put('id3', params[:id3])
    campaign.put('username', params[:username])
    campaign.put('password', params[:password])
    campaign.put('event1', params[:event1])
    campaign.put('event2', params[:event2])
    campaign.put('event3', params[:event3])
    campaign.put('event4', params[:event4])
    campaign.put('event5', params[:event5])
    
    campaign.save

  
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
    
  end
  
end
