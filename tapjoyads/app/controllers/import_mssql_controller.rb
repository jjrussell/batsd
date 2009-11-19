require 'base64'

class ImportMssqlController < ApplicationController
  include TimeLogHelper
  
  protect_from_forgery :except => [:publisher_ad, :app, :campaign]
  
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
    app.put('launhced', params[:launched])
    app.put('status', params[:status])
    app.put('color', params[:color])
    app.put('description_1', params[:description][0,999])
    app.put('description_2', params[:description][1000,1999]) if params[:description].length > 1000
    app.put('description_3', params[:description][2000,2999]) if params[:description].length > 2000
    app.put('description_4', params[:description][3000,3999]) if params[:description].length > 3000
    app.put('has_location', params[:has_location])
    app.put('ad_space', {
      :name => "1",
      :has_location => params[:has_location],
      :rotation_direction => params[:rotation_direction]
       }.to_json)

    app.save

    time_log("Stored in s3") do
      AWS::S3::S3Object.store app_id, params[:icon], 'app-icons'
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
