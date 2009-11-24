require 'cgi'
require 'uri'
require 'net/http'
require 'json'
require 'xml'
require 'base64'
require 'RMagick'
require 'hpricot'
include Magick
require 'activemessaging/processor'

class GetadController < ApplicationController
  include DownloadContent
  include MemcachedHelper

  missing_message = "missing required params"
  verify :params => [:udid, :app_id],
         :render => {:text => missing_message}
  verify :params => [:apid, :auid],
         :only => :millennial,
         :render => {:text => missing_message}
  verify :params => [:apikey, :appkey],
         :render => {:text => missing_message},
         :only => :mdotm
  verify :params => [:slot_id],
         :render => {:text => missing_message},
         :only => :adfonic
  verify :params => [:partner_key, :site_key, :zone_key],
         :render => {:text => missing_message},
         :only => :crisp
         
  around_filter :catch_exceptions
  
  USER_AGENT = CGI::escape("Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X)" +
      " AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20")

  def millennial
    url = 'http://ads.mp.mydas.mobi/getAd.php5' +
        "?apid=#{CGI::escape(params[:apid])}" +
        "&auid=#{CGI::escape(params[:auid])}" +
        "&uip=#{get_ip_address}" +
        "&ua=#{USER_AGENT}"
    
    content = download_content(url)

    @ad_return_obj = TapjoyAd.new
    
    if /^<\?xml/.match(content)
      doc =  XML::Parser.string(content).parse
    
      click_url = doc.find('//ad/clickUrl').first.content
      image_url = doc.find('//ad/image/url').first.content
      if image_url.empty?
        no_ad
        return
      end
      image = download_image image_url
      
      @ad_return_obj.ClickURL = click_url
      @ad_return_obj.Image = image
      
      render_ad
    elsif /^GIF/.match(content)
      logger.info "gif image"
      no_ad
    elsif /^<link/.match(content)
      logger.info "rich media ad"
      doc = Hpricot.parse(content)
      link = (doc/"a").first["href"]
      image_url = (doc/"img").first["src"]
      image = download_image image_url
      
      @ad_return_obj.ClickURL = link
      @ad_return_obj.Image = image
      #@ad_return_obj.OpenIn = "Webview"
      
      #set tracking data for millennial
      tracker_url = (doc/"img")[1]["src"]
      download_content tracker_url

      render_ad
    else
      logger.info "html ad"
      #@ad_return_obj.AdHTML = content
      no_ad
    end
  end

  def mdotm
    url = 'http://ads.mdotm.com/ads/feed.php' + 
        "?apikey=#{CGI::escape(params[:apikey])}" +
        "&appkey=#{CGI::escape(params[:appkey])}" +
        "&deviceid=#{CGI::escape(params[:udid])}" +
        "&width=320&height=50" +
        "&platform=iphone" +
        "&fmt=json" +
        "&clientip=#{get_ip_address}"
    
    json_string = download_content(url)
    json = JSON.parse(json_string).first
    
    if !json or json.length == 0
      logger.info "empty json"
      no_ad
    else
      @ad_return_obj = TapjoyAd.new
    
      if json['ad_type'] == 1
        @ad_return_obj.ClickURL = json['landing_url']
        @ad_return_obj.Image = download_image json['img_url']
      elsif json['ad_type'] == 2
        #TODO: draw text and image
        #@ad_return_obj.ClickURL = json['landing_url']
        logger.info "Type 2 ad not yet implemented"
        no_ad
        return
      elsif json['ad_type'] == 3
        #@ad_return_obj.AdHTML = json['ad_text']
        logger.info "html ad"
        no_ad
        return
      end
    
      @ad_return_obj.OpenIn = json['launch_type'] == 2 ? 'Webview' : 'Safari'
    
      render_ad
    end
  end
  
  def adfonic
    url = "http://adfonic.net/ad/#{CGI::escape(params[:slot_id])}" +
        "?r.ip=#{get_ip_address}" +
        "&r.id=#{CGI::escape(params[:udid])}" +
        "&test=0" +
        "&t.format=json" +
        "&t.markup=0" +
        "&h.user-agent=#{USER_AGENT}"
    
    json_string = download_content(url)
    
    json = JSON.parse(json_string)
    
    if !json or json['status'] == 'error'
      logger.info "Ad network reported an error"
      no_ad
    else
      @ad_return_obj = TapjoyAd.new
      @ad_return_obj.ClickURL = json['destination']['url']
      if json['components']['image']
        image_url = json['components']['image']['url']
        image = download_image image_url
      else
        text = json['components']['text']['content']
        image = get_from_cache_and_save("img.#{text.hash}") do
          start_time = Time.now
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
          image = Base64.encode64(image_array[0].to_blob)
          logger.info "image generation time: #{Time.now - start_time}"
          image
        end
      end
      
      @ad_return_obj.Image = image
      render_ad
    end
  end
  
  def crisp
    # http://adserviceapi.qa.mlogic.be/adRequest.v1/single/ad.json?
    # partnerkey=67934ffbf308992b66b77856abb2abc7&sitekey=tapjoy-test&random=64223321&zonekey=Default&sectionkey=home
    
    #url = "http://adserviceapi.qa.mlogic.be/adRequest.v1/single/ad.json" +
    url = "http://test-api.crispwireless.com/adRequest.v1/single/ad.json" +
        "?partnerkey=#{CGI::escape(params[:partner_key])}" + 
        "&sitekey=#{CGI::escape(params[:site_key])}" +
        "&random=#{rand(9999999)}" +
        "&rspid=" +
        "&zonekey=#{CGI::escape(params[:zone_key])}" +
        "&sectionkey=home"
    
    # old url, keep until crisp verifies the new url works
    # url = "http://api.crispwireless.com/adRequest.v1/single/ad.html" +
    #     "?partnerkey=#{CGI::escape(params[:partner_key])}" + 
    #     "&sitekey=#{CGI::escape(params[:site_key])}" +
    #     "&random=#{rand(9999999)}" +
    #     "&rspid=" +
    #     "&zonekey=#{CGI::escape(params[:zone_key])}" +
    #     "&sectionkey"
    
    json_string = download_content(url, {:headers => {'User-Agent' => request.headers['User-Agent']}})
    
    json = JSON.parse(json_string)
    
    if !json or !json['html']
      no_ad
    elsif json['clickURL'] != '' && json['mediaSourceURL'] != ''
      @ad_return_obj = TapjoyAd.new
      @ad_return_obj.ClickURL = json['clickURL']
      image_url = json['mediaSourceURL']
      @ad_return_obj.Image = download_image image_url if image_url
      render_ad
    else
      @ad_return_obj = TapjoyAd.new
      @ad_return_obj.AdHTML = json['html']
      render_ad
    end
  end
  
  def socialreach
    num = rand(6) + 6251 # 6521 <= num <= 6256
    
    @ad_return_obj = TapjoyAd.new
    @ad_return_obj.OpenIn = 'Webview'
    @ad_return_obj.ClickURL = "http://clicks.socialreach.com/click?zone=#{num}"
    
    image_name = "socialreach-#{num}.jpg"
    
    image = get_from_cache_and_save("img.s3.#{image_name.hash}") do
      image_content = AWS::S3::S3Object.value image_name, 'adimages'
      Base64.encode64 image_content
    end
    
    @ad_return_obj.Image = image
    
    render_ad
  end
  
  def publisher_ad
    
    ad_id = params[:ad_id]
    udid = params[:udid]
    
    ad = PublisherAd.new(ad_id)
    
    if (not ad.get('url'))
      error = ::Error.new
      error.put('request', request.url)
      error.put('function', 'getad/publisher_ad')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "can't find ad_id in simpledb: #{ad_id}"

      no_ad
      return
    end
    
    #todo daily/global limits???
    
    @ad_return_obj = TapjoyAd.new
        
    url = ad.get('url')
    open_in = ad.get('open_in')
    open_in = 'Safari' if open_in.nil?
    
    app_id_to_advertise = ad.get('app_id_to_advertise')
    
        
    if (app_id_to_advertise)
      #todo is it installed??
      open_in = 'Safari'
      #@ad_return_obj.GameID = app_id_to_advertise
    end
    
    @ad_return_obj.OpenIn = open_in
    @ad_return_obj.ClickURL = url
    @ad_return_obj.AdID = ad_id
    
    image = get_from_cache_and_save("img.s3.#{ad_id}") do
      image_content = AWS::S3::S3Object.value "base64.#{ad_id}", 'publisher-ads'
    end
    
    @ad_return_obj.Image = image
    @ad_return_obj.AdImpressionID = params[:campaign_id]
    
    render_ad
  end
  
  private
  def get_ip_address
    ip_address = request.remote_ip
    if ip_address == '127.0.0.1'
      ip_address = '72.164.173.18'
    end
    return ip_address
  end
  
  def download_image image_url
    get_from_cache_and_save("img.#{image_url.hash}") do 
      Base64.encode64 download_content(image_url)
    end
  end
  
  def render_ad
    logger.info "Ad rendered"
    @ad_rendered = true
    respond_to do |f|
      f.xml {render(:partial => 'tapjoy_ad')}
    end
  end
  
  def no_ad
    logger.info "No ad returned"
    render :text => "no ad"
  end
  
  def catch_exceptions
    yield
  rescue Patron::TimeoutError
    logger.info "Download timed out"
    no_ad
  rescue Patron::HostResolutionError
    logger.info "Name resolution error when downloading"
    no_ad
  rescue Patron::ConnectionFailed
    logger.info "ConnectionFailed error when downloading"
    no_ad
  rescue JSON::ParserError
    logger.info "Error parsing json"
    no_ad
  end
end
