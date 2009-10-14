require 'net/http'

class GetadController < ApplicationController

  def adfonic
    respond_to do |f|  
      @ad_return_obj = TapjoyAd.new
      @ad_return_obj.ClickURL = 'http://sample.com'
      @ad_return_obj.Image = '9823897239487239487'
      f.xml {render(:partial => 'tapjoy_ad')}
    end
  end
  
  def crisp
    respond_to do |f|
      #store the app and device in our system
      store_device(params[:udid])
      store_app(params[:app_id])
      
      partner_key = params[:partner_key]
      site_key = params[:site_key]
      zone_key = params[:zone_key]
      user_agent = request.headers['User-Agent']
           
      host = 'api.crispwireless.com'
      path = "/adRequest.v1/single/ad.html" +
          "?partnerkey=#{partner_key}" + 
          "&sitekey=#{site_key}" +
          "&random=#{rand(9999999)}" +
          "&rspid=" +
          "&zonekey=#{zone_key}" +
          "&sectionkey"
      
      html = ''
      Net::HTTP.start(host) do |http|
        html = http.get(path, "User-Agent" =>user_agent).body
      end
      
      if html.include? 'Error: Empty ad'
        @ad_return_obj = nil
        f.html {render(:text => "no ad")}
      else
        @ad_return_obj = TapjoyAd.new
        @ad_return_obj.AdHTML = html
        f.xml {render(:partial => 'tapjoy_ad')}
      end
    end
  end
  
  private
  def store_device(udid)
    get_model_atomically(Device, :udid, udid) do |m|
      m.count = m.count.to_i + 1
    end
  end
  
  def store_app(app_id)
    get_model_atomically(App, :app_id, app_id) do |m|
      m.count = m.count.to_i + 1
    end
  end
  
  def get_model_atomically(model_class, key_name, key_value)
    wait_until_lock_free(key_value) do
      model_class
      model = CACHE.get(key_value)
      unless model
        puts "Not in cache, getting from simpledb"
        model = model_class.find(:first, :params => {key_name => key_value})
      end
      
      unless model
        puts "Not in cache or simpledb, creating new"
        model = model_class.new
        model.attributes[key_name] = key_value
        model.count = 0
      end
      
      yield model
      
      model.save
      CACHE.set(key_value, model, 1.hour)
    end
  end
  
  def wait_until_lock_free(key)
    lock_key = "LOCK_#{key}"
    begin
      while CACHE.add(lock_key, nil).index('NOT_STORED') == 0
        sleep(0.1)
      end
      yield
    ensure
      CACHE.delete(lock_key)
    end
  end
  
end
