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
    wait_until_lock_free(udid) do
      Device
      device = CACHE.get(udid)
      unless device
        device = Device.find(:first, :params => { :udid => udid } )
      end
    
      if device
        device.count = device.count.to_i + 1  
      else
        device = Device.new
        device.udid = udid
        device.count = 1
      end
      CACHE.set(udid, device, 1.hour)
      device.save
    end
  end
  
  def store_app(app_id)
    wait_until_lock_free(app_id) do
      App
      app = CACHE.get(app_id)
      unless app
        app = App.find(:first, :params => { :appid => app_id } )
      end
      if app
        app.count = app.count.to_i + 1
      else
        app = App.new
        app.appid = app_id
        app.count = 1
      end
      CACHE.set(app_id, app, 1.hour)
      app.save
    end
  end
  
  def wait_until_lock_free(key)
    lock_key = "LOCK_#{key}"
    while CACHE.add(lock_key, nil).index('NOT_STORED') == 0
      sleep(0.1)
    end
    yield
    CACHE.delete(lock_key)
  end
  
end
