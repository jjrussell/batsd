require 'net/http'
require 'json'
require 'xml'
require 'base64'
require 'RMagick'
include Magick

class GetadController < ApplicationController

  #before_filter :store_device

  USER_AGENT = CGI::escape("Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X)" +
      " AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20")

  def millennial
    respond_to do |f|
      apid = params[:apid]
      auid = params[:auid]
      ip_address = get_ip_address
      
      url = 'http://ads.mp.mydas.mobi/getAd.php5' +
          "?apid=#{apid}" +
          "&auid=#{auid}" +
          "&ip=#{ip_address}" +
          "&ua=#{USER_AGENT}"
      
      content = download_content(URI.parse(url))

      @ad_return_obj = TapjoyAd.new
      
      if /^<\?xml/.match(content)
        doc =  XML::Parser.string(content).parse
      
        click_url = doc.find('//ad/clickUrl').first.content
        image_url = doc.find('//ad/image/url').first.content
        image = download_content(URI.parse(image_url))
        
        @ad_return_obj.ClickURL = click_url
        @ad_return_obj.Image = Base64.encode64(image)
        
        f.xml {render(:partial => 'tapjoy_ad')}
      elsif /^GIF/.match(content)
        f.html {render(:text => "no ad")}
      else
        @ad_return_obj.AdHTML = content
        f.html {render(:text => "no ad")}
      end
    end
  end

  def mdotm
    respond_to do |f|
      udid = params[:udid]
      apikey = CGI::escape(params[:apikey])
      appkey = CGI::escape(params[:appkey])
      ip_address = get_ip_address
      
      url = 'http://ads.mdotm.com/ads/feed.php' + 
          "?apikey=#{apikey}" +
          "&appkey=#{appkey}" +
          "&deviceid=#{udid}" +
          "&width=320&height=50" +
          "&platform=iphone" +
          "&fmt=json" +
          "&clientip=#{ip_address}"
      
      json_string = download_content(URI.parse(url))
      json = JSON.parse(json_string).first
      
      if !json or json.length == 0
        f.html {render(:text => "no ad")}
      else
        @ad_return_obj = TapjoyAd.new
      
        if json['ad_type'] == 1
          image_url = json['img_url']
          image = download_content(URI.parse(image_url))
          @ad_return_obj.ClickURL = json['landing_url']
          @ad_return_obj.Image = Base64.encode64(image)
        elsif json['ad_type'] == 2
          #TODO: draw text and image
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
  end

  def adfonic
    respond_to do |f|
      udid = params[:udid]
      slot_id = params[:slot_id]
      ip_address = get_ip_address
      
      url = "http://adfonic.net/ad/#{slot_id}" +
          "?r.ip=#{ip_address}" +
          "&r.id=#{udid}" +
          "&test=0" +
          "&t.format=json" +
          "&t.markup=0" +
          "&h.user-agent=#{USER_AGENT}"
      
      json_string = download_content(URI.parse(url))
      
      json = JSON.parse(json_string)
      if json['status'] == 'error'
        f.html {render(:text => "no ad")}
      else
        @ad_return_obj = TapjoyAd.new
        @ad_return_obj.ClickURL = json['destination']['url']
        if json['components']['image']
          image_url = json['components']['image']['url']
          image = download_content(URI.parse(image_url))
        else
          start_time = Time.now
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
          logger.info "image generation time: #{Time.now - start_time}"
        end
        
        @ad_return_obj.Image = Base64.encode64(image)
        f.xml {render(:partial => 'tapjoy_ad')}
      end
      
    end
  end
  
  def crisp
    respond_to do |f|
      partner_key = params[:partner_key]
      site_key = params[:site_key]
      zone_key = params[:zone_key]
      user_agent = request.headers['User-Agent']
           
      url = "http://api.crispwireless.com/adRequest.v1/single/ad.html" +
          "?partnerkey=#{partner_key}" + 
          "&sitekey=#{site_key}" +
          "&random=#{rand(9999999)}" +
          "&rspid=" +
          "&zonekey=#{zone_key}" +
          "&sectionkey"
      
      html = download_content(URI.parse(url), 'User-Agent' => user_agent)
      
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
  def get_ip_address
    ip_address = request.remote_ip
    if ip_address == '127.0.0.1'
      ip_address = '72.164.173.18'
    end
    return ip_address
  end
  
  def download_content(uri, *headers)
    start_time = Time.now
    
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 3
      content = http.get(uri.request_uri, *headers)
    end
    
    content = res.body
    
    logger.info "Downloaded #{uri.to_s} (#{Time.now - start_time}s)"
    
    return content
  end
  
  def store_device
    udid = params[:udid]
    get_model_atomically(Device, :udid, udid) do |m|
      m.count = m.count.to_i + 1
    end
  end
  
  def store_app
    app_id = params[:app_id]
    get_model_atomically(App, :app_id, app_id) do |m|
      m.count = m.count.to_i + 1
    end
  end
  
  def get_model_atomically(model_class, key_name, key_value)
    wait_until_lock_free(key_value) do
      model_class
      model = CACHE.get(key_value)
      unless model
        model = model_class.find(:first, :params => {key_name => key_value})
      end
      
      unless model
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
        logger.info('sleeping')
      end
      yield
    ensure
      CACHE.delete(lock_key)
    end
  end
  
end
