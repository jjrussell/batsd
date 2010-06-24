require 'base64'

class ImportMssqlController < ApplicationController
  include TimeLogHelper
  include MemcachedHelper
  include DownloadContent
  
  protect_from_forgery :except => [:publisher_ad, :app, :campaign]

  def user
    user = User.find_or_initialize_by_id(params[:user_id])
    user.username = params[:user_name]
    user.email = params[:email]
    user.crypted_password = params[:password]
    user.password_salt = params[:salt]
    if user.new_record?
      user.user_roles << UserRole.find_by_name('partner')
      user.partners << Partner.find(params[:partner_id]) unless params[:partner_id].blank? || params[:partner_id] == 'NULL'
    end
    user.created_at = Time.parse(params[:created_at] + ' CST').utc unless params[:created_at].blank?
    user.save(false)
    
    render :template => 'layouts/success'  
  end
  
  def purchased_item
    udid = params[:udid]
    app_id = params[:app_id]
    pi = PointPurchases.new(:key => "#{udid}.#{app_id}")
    pi.add_virtual_good(params[:item_id])
    pi.save
    
    render :template => 'layouts/success'
    
  end

  def points
    udid = params[:udid]
    app_id = params[:app_id]
    pi = PointPurchases.new(:key => "#{udid}.#{app_id}")
    pi.points = params[:points]
    pi.save
    
    render :template => 'layouts/success'
    
  end

  def vg
    vg = VirtualGood.new(:key => params[:item_id])
    vg.apple_id = params[:apple_id]
    vg.price = params[:price]
    vg.name = params[:name]
    vg.description = params[:description]
    vg.file_size = params[:file_size]
    vg.max_purchases = params[:max_purchases]
    vg.disabled = params[:disabled] == '1'
    vg.beta = params[:beta] == 'True'
    vg.title = params[:title]
    vg.app_id = params[:app_id]
    
    extra_attributes = {}
    keys = (params[:attributes] || '').split(';')
    values = (params[:values] || '').split(';')
    keys.each_index do |i|
      extra_attributes[keys[i]] = values[i]
    end
    vg.extra_attributes = extra_attributes
    
    bucket = RightAws::S3.new.bucket('virtual_goods')
    
    if vg.has_icon = (params[:thumb_image] != 'None')
      thumb_image = download_content(params[:thumb_image], :timeout => 30)
      bucket.put("icons/#{params[:item_id]}.png", thumb_image, {}, 'public-read')
    end
    
    if vg.has_data = (params[:datafile] != 'None')
      datafile = download_content(params[:datafile], :timeout => 30)
      bucket.put("data/#{params[:item_id]}.zip", datafile, {}, 'public-read')
    end
    
    vg.save
    
    render :template => 'layouts/success' 
  end
  
  def partner
    return unless verify_params([:partner_id])
    
    partner = Partner.find_or_initialize_by_id(params[:partner_id])
    partner.name = params[:name] unless params[:name].blank?
    partner.contact_name = params[:contact_name] unless params[:contact_name].blank?
    partner.contact_phone = params[:contact_phone] unless params[:contact_phone].blank?
    partner.updated_at = Time.parse(params[:updated_at] + ' CST').utc
    partner.created_at = Time.parse(params[:created_at] + ' CST').utc
    
    partner.save!
    
    render :template => 'layouts/success' 
  end
  
  def currency
    return unless verify_params([:app_id])
    
    currency = Currency.find_or_initialize_by_app_id(params[:app_id])
    currency.partner = currency.app.partner
    currency.name = params[:currency_name]
    currency.conversion_rate = params[:conversion_rate]
    currency.initial_balance = params[:initial_balance].to_i
    currency.has_virtual_goods = params[:virtual_goods_currency] == 'True'
    currency.secret_key = (params[:secret_key] == 'None' || params[:secret_key].blank?) ? nil : params[:secret_key]
    currency.callback_url = params[:callback_url]
    currency.offers_money_share = params[:offers_money_share].to_f unless params[:offers_money_share].blank?
    currency.installs_money_share = params[:installs_money_share].to_f unless params[:installs_money_share].blank?
    currency.disabled_offers = ( (params[:disabled_offers] || '').split(';') + (params[:disabled_apps] || '').split(';') ).uniq.reject {|item| item == '' }.join(';')
    currency.only_free_offers = params[:only_free_apps] == '1'
    currency.send_offer_data = params[:send_offer_data] == '1'
    currency.test_devices = params[:beta_devices]
    currency.save!
    
    if params[:show_rating_offer] == '1'
      rating_offer = RatingOffer.find_or_initialize_by_app_id_and_partner_id(params[:app_id], currency.app.partner_id)
      rating_offer.save!
    end
    
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

    bucket = RightAws::S3.new.bucket('app_data')
    bucket.put("icons/#{params[:app_id]}.png", params[:icon], {}, 'public-read')
    bucket.put("screenshots/#{params[:app_id]}.png", params[:screenshot], {}, 'public-read')
    save_to_cache("icon.s3.#{params[:app_id]}", Base64.encode64(params[:icon]))
    
    offer = nil
    unless params[:name].starts_with?('Email')
      mysql_app = App.find_or_initialize_by_id(params[:app_id])
      mysql_app.partner_id = params[:partner_id]
      mysql_app.name = params[:name]
      mysql_app.description = params[:description] unless params[:description].blank?
      mysql_app.price = params[:price].to_i
      mysql_app.platform = params[:os_type]
      mysql_app.store_id = mysql_app.parse_store_id_from_url(params[:store_url], false)
      mysql_app.store_url = params[:store_url] unless params[:store_url].blank? || params[:store_url] == 'None'
      mysql_app.color = params[:primary_color].to_i
      mysql_app.rotation_direction = params[:rotation_direction]
      mysql_app.rotation_time = params[:rotation_time]
      mysql_app.created_at = Time.parse(params[:created_at] + ' CST').utc
      mysql_app.save!
      
      offer = mysql_app.offer
      if params[:iphone_only] == '1'
        offer.device_types = [ 'iphone' ].to_json
      end
      
    else
      email_offer = EmailOffer.find_or_initialize_by_id(params[:app_id])
      email_offer.partner_id = params[:partner_id]
      email_offer.name = params[:name]
      email_offer.description = params[:description] unless params[:description].blank?
      email_offer.created_at = Time.parse(params[:created_at] + ' CST').utc
      email_offer.save!
      
      offer = email_offer.offer
      
    end
    offer.user_enabled = params[:payment_for_install].to_i > 0
    offer.payment = params[:payment_for_install].to_i
    offer.next_stats_aggregation_time = Time.zone.now if offer.next_stats_aggregation_time.blank?
    offer.stats_aggregation_interval = 3600 if offer.stats_aggregation_interval.blank?
    offer.created_at = offer.item.created_at
    offer.save!
    
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
    campaign.put('id1', params[:id1], :cgi_escape => true)
    campaign.put('id2', params[:id2], :cgi_escape => true)   
    campaign.put('id3', params[:id3], :cgi_escape => true)
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
  
  def order
    order = Order.find_or_initialize_by_id(params[:id])
    order.partner_id = params[:partner_id]
    order.payment_txn_id = params[:payment_txn_id] unless params[:payment_txn_id].blank?
    order.refund_txn_id = params[:refund_txn_id] unless params[:refund_txn_id].blank?
    order.coupon_id = params[:coupon_id] unless params[:coupon_id].blank?
    order.status = params[:status]
    order.payment_method = params[:payment_method]
    order.amount = params[:amount]
    
    order.updated_at = Time.parse(params[:updated_at] + ' CST').utc
    order.created_at = Time.parse(params[:created_at] + ' CST').utc
    
    order.save!
    
    render :template => 'layouts/success'
  end
  
  def payout
    payout = Payout.find_or_initialize_by_id(params[:id])
    payout.partner_id = params[:partner_id]
    payout.amount = params[:amount]
    payout.month = params[:month]
    payout.year = params[:year]
    payout.status = params[:status]
    
    payout.updated_at = Time.parse(params[:updated_at] + ' CST').utc
    payout.created_at = Time.parse(params[:created_at] + ' CST').utc
    
    payout.save!
    
    render :template => 'layouts/success'
  end
  
end
