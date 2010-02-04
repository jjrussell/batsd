require 'base64'

class ImportMssqlController < ApplicationController
  include TimeLogHelper
  include MemcachedHelper
  
  protect_from_forgery :except => [:publisher_ad, :app, :campaign]

  def user
    user = User.new(:key => params[:user_id])
    user.put('user_id', params[:user_id])
    user.put('partner_id', params[:partner_id])
    user.put('email', params[:email])
    user.put('user_name', params[:user_name])
    user.put('password', params[:password])
    user.put('salt', params[:salt])

    user.save

    render :template => 'layouts/success'  
  end

  def vg
    vg = VirtualGood.new(:key => params[:item_id])
    vg.put('attributes', params[:attributes], :cgi_escape => true)
    vg.put('values', params[:values], :cgi_escape => true)
    vg.put('apple_id', params[:apple_id])
    vg.put('price', params[:price])
    vg.put('name', params[:name], :cgi_escape => true)
    vg.put('description', params[:description], :cgi_escape => true)
    vg.put('file_size', params[:file_size])
    vg.put('disabled', params[:disabled])
    vg.put('beta', params[:beta])
    vg.put('title', params[:title])
    vg.put('app_id', params[:app_id])
    
    vg.save
    
    AWS::S3::S3Object.store "icon.#{params[:item_id]}", params[:thumb_image], 'virtual_goods'
    save_to_cache("vg.icon.s3.#{params[:item_id].hash}", Base64.encode64(params[:thumb_image]))

    AWS::S3::S3Object.store  "datafile.#{params[:item_id]}", params[:datafile], 'virtual_goods'
    save_to_cache("vg.datafile.s3.#{params[:item_id].hash}", params[:datafile])
        
    render :template => 'layouts/success' 
  end
  
  def partner
    return unless verify_params([:partner_id])

    partner = Partner.new(:key => params[:partner_id])
    partner.put('partner_id', params[:partner_id])
    partner.put('contact_name', params[:contact_name])
    partner.put('contact_phone', params[:contact_phone])
    partner.put('paypal', params[:paypal])
    partner.put('referrer', params[:referrer])
    partner.put('offerpal_sales', (params[:referrer][0..3] == "OPM-") ? '1' : '0')
    partner.put('last_windows_login', Time.parse(params[:last_login] + ' CST').utc.to_f.to_s)
    partner.put('apps',params[:apps], {:cgi_escape => true})
    
    partner.save

    render :template => 'layouts/success' 
  end
      
  def currency
    return unless verify_params([:app_id])
    
    currency = Currency.new(:key => params[:app_id])
    
    currency.put('currency_name',params[:currency_name])
    currency.put('conversion_rate', params[:conversion_rate])
    currency.put('initial_balance', params[:initial_balance])
    currency.put('virtual_goods_currency', params[:virtual_goods_currency])
    currency.put('secret_key', params[:secret_key]) if params[:secret_key] != ''
    currency.put('callback_url', params[:callback_url])
    currency.put('cs_callback_url', params[:cs_callback_url])
    currency.put('offers_money_share', params[:offers_money_share])
    currency.put('installs_money_share', params[:installs_money_share])
    currency.put('disabled_offers', params[:disabled_offers])
    currency.put('disabled_apps', params[:disabled_apps]) 
    currency.put('only_free_apps', params[:only_free_apps])
    currency.put('show_rating_offer', params[:show_rating_offer])
    currency.put('send_offer_data', params[:send_offer_data])

    currency.save

    render :template => 'layouts/success'
  end
  
  def publisher_ad
    return unless verify_params([:ad_id, :partner_id])
    
    ad_id = params[:ad_id]
  
    ad = PublisherAd.new(:key => ad_id)
    
    unless ad.get('next_run_time')
      ad.put('next_run_time', Time.now.utc.to_f.to_s)     
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
  
    #store an image in s3
    AWS::S3::S3Object.store "raw." + ad_id, params[:image], 'publisher-ads'
    AWS::S3::S3Object.store "base64." + ad_id, Base64.b64encode(params[:image]), 'publisher-ads'
  
    render :template => 'layouts/success'
  end
  
  def app
    return unless verify_params([:app_id])

    app_id = params[:app_id]

    app = App.new(:key => app_id)
    
    unless app.get('next_run_time')
      app.put('next_run_time', Time.now.utc.to_f.to_s)     
      app.put('interval_update_time','60')
    end

    unless app.get('next_ad_optimization_time')
      app.put('next_ad_optimization_time', Time.now.utc.to_f.to_s)     
      app.put('ad_optimization_interval_update_time','60')
    end

    app.put('name',params[:name], {:cgi_escape => true})
    app.put('payment_for_install', params[:payment_for_install])
    app.put('rewarded_installs_ordinal', params[:rewarded_installs_ordinal])
    app.put('install_tracking', params[:install_tracking])
    app.put('store_url', params[:store_url])
    app.put('partner_id', params[:partner_id])
    app.put('os', params[:os])
    app.put('launched', params[:launched])
    app.put('pay_per_click', params[:pay_per_click])
    app.put('status', params[:status])
    app.put('color', params[:color])
    app.put('price', params[:price]) 
    app.put('description', params[:description], {:cgi_escape => true}) if params[:description]
    app.put('has_location', params[:has_location])
    app.put('rotation_time', params[:rotation_time])
    app.put('rotation_direction', params[:rotation_direction])
    app.put('balance', params[:balance])
    app.put('iphone_only', params[:iphone_only]) if params[:iphone_only]
    app.put('daily_budget', params[:daily_budget]) if params[:daily_budget]
    app.put('os_type', params[:os_type])
    
    app.delete('description_1') if app.get('description_1')
    app.delete('description_2') if app.get('description_2')
    app.delete('description_3') if app.get('description_3')

    app.save

    AWS::S3::S3Object.store app_id, params[:icon], 'app-icons'
    save_to_cache("icon.s3.#{app_id.hash}", Base64.encode64(params[:icon]))
    save_to_cache("img.icon.s3.#{app_id.hash}", params[:icon])
    AWS::S3::S3Object.store app_id, params[:screenshot], 'app-screenshots'

    render :template => 'layouts/success'
  end
    
  def campaign
    return unless verify_params([:app_id, :campaign_id])
    
    campaign_id = params[:campaign_id]
  
    campaign = Campaign.new(:key => campaign_id)
    
    unless campaign.get('next_run_time')
      campaign.put('next_run_time', Time.now.utc.to_f.to_s)     
      campaign.put('interval_update_time','60')
    end
    
    unless campaign.get('next_ecpm_update')
      campaign.put('next_ecpm_update', Time.now.utc.to_f.to_s)     
      campaign.put('ecpm_interval_update_time','3660') #update ecpm once an hour at most
    end

    padded_ecpm = '%08d' % (params[:ecpm].to_f * 100)
    campaign.put('ecpm', padded_ecpm)
    
    campaign.put('app_id', params[:app_id])
    campaign.put('ad_space', '1')
    campaign.put('network_id', params[:network_id])
    campaign.put('network_name', params[:network_name])
    campaign.put('name', params[:name])
    campaign.put('description', params[:description])
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
    campaign.put('library_name', params[:library_name])
    
    campaign.save
  
    render :template => 'layouts/success'
  end
end
