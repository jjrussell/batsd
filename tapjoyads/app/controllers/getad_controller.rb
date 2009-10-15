require 'net/http'
require 'json'
require 'base64'
require 'RMagick'
include Magick

class GetadController < ApplicationController

  def mdotm
    respond_to do |f|
      #store the app and device in our system
      store_device(params[:udid])
      store_app(params[:app_id])
      
      udid = params[:udid]
      apikey = CGI::escape(params[:apikey])
      appkey = CGI::escape(params[:appkey])
      ip_address = request.remote_ip
      
      if ip_address == '127.0.0.1'
        ip_address = '72.164.173.18'
      end
      
      host = 'ads.mdotm.com'
      path = '/ads/feed.php' + 
          "?apikey=#{apikey}" +
          "&appkey=#{appkey}" +
          "&deviceid=#{udid}" +
          "&width=320&height=50" +
          "&platform=iphone" +
          "&fmt=json" +
          "&clientip=#{ip_address}"
      
      logger.info "URL:" + "http://#{host}#{path}"
      
      jsonString = Net::HTTP.get(URI.parse("http://#{host}#{path}"))
      logger.info "JSON:" + jsonString
      json = JSON.parse(jsonString).first
      
      @ad_return_obj = TapjoyAd.new
      
      if json['ad_type'] == 1
        image_url = json['img_url']
        image = Net::HTTP.get(URI.parse(image_url))
        @ad_return_obj.ClickURL = json['landing_url']
        @ad_return_obj.Image = Base64.encode64(image)
      elsif json['ad_type'] == 2
        #draw text and image
        @ad_return_obj.ClickURL = json['landing_url']
      elsif json['ad_type'] == 3
        @ad_return_obj.AdHTML = json['ad_text']
      end
      
      if json['lanuch_type'] == 2
        @ad_return_obj.OpenIn = 'Webview'
      else
        @ad_return_obj.OpenIn = 'Safari'
      end
      
      f.xml {render(:partial => 'tapjoy_ad')}
    end
  end

  def adfonic
    respond_to do |f|
      #store the app and device in our system
      store_device(params[:udid])
      store_app(params[:app_id])
      
      udid = params[:udid]
      slot_id = params[:slot_id]
      user_agent = CGI::escape("Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X)" +
          " AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20")
      ip_address = request.remote_ip
      if ip_address == '127.0.0.1'
        ip_address = '72.164.173.18'
      end
      
      host = 'adfonic.net'
      path = "/ad/#{slot_id}" +
          "?r.ip=#{ip_address}" +
          "&r.id=#{udid}" +
          "&test=0" +
          "&t.format=json" +
          "&t.markup=0" +
          "&h.user-agent=#{user_agent}"
      
      #jsonString = Net::HTTP.get(URI.parse(host + path))
      jsonString = ''
      Net::HTTP.start(host) do |http|
        jsonString = http.get(path).body
      end
      
      json = JSON.parse(jsonString)
      if json['status'] == 'error'
        f.html {render(:text => "no ad")}
      else
        @ad_return_obj = TapjoyAd.new
        @ad_return_obj.ClickURL = json['destination']['url']
        if json['components']['image']
          image_url = json['components']['image']['url']
          image = Net::HTTP.get(URI.parse(image_url))
        else
          text = json['components']['text']['content']
          image_array = Image.read("caption:#{text}") do
            self.size = "320x50"
            self.pointsize = 18
            self.font = 'times'
            self.antialias = true
            self.stroke_width = 1
            self.gravity = CenterGravity
            self.stroke = 'white'
            self.fill = 'white'
            self.undercolor = 'black'
            self.background_color = 'black'
            self.border_color = 'blue'
          end
          image_array[0].format = 'png'
          image = image_array[0].to_blob
        end
        
        @ad_return_obj.Image = Base64.encode64(image)
        f.xml {render(:partial => 'tapjoy_ad')}
      end
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
        html = http.get(path, "User-Agent" => user_agent).body
      end
      
      if html.include? 'Error: Empty ad'
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
