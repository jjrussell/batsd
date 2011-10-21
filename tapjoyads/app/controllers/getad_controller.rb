class GetadController < ApplicationController

  around_filter :catch_exceptions

  USER_AGENT = CGI::escape("Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X)" +
      " AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5A345 Safari/525.20")

  def index
    if params[:campaign_id] == ""
      return socialreach
    end

    return unless verify_params([:udid, :app_id, :campaign_id])

    campaign = Campaign.new(:key => params[:campaign_id])
    network_name = campaign.get('network_name')

    Rails.logger.info "network_name: #{network_name}"

    path = case network_name
    when "Millennial"
      return millennial(campaign.get('id1'), campaign.get('id2'))
    when "MDotM"
      no_ad
      return
    when "Adfonic"
      return adfonic(campaign.get('id1'))
    when "Crisp"
      return crisp(campaign.get('id1'), campaign.get('id2'), campaign.get('id3'))
    when "SocialReach"
      return socialreach
    when "TapjoyAds"
      #return publisher_ad('35e27740-d857-45a6-9f59-1529be64914a')  #4info microsoft
      #return publisher_ad('ce91beeb-a19b-4389-acc4-a55e3cd626d4') #4info best buy
      return socialreach
    when "PublisherAds"
      return publisher_ad(campaign.get('ad_id'))
    else
      # The default ad shouldn't be showing up. If it does, we randomly throw an error, so that
      # it wil show up in the newrelic logs. The client will re-request.
      # TODO: use newrelic gem api to log error.
      raise("campaign #{params[:campaign_id]} not found") if rand(100) == 1
      return socialreach
    end

  end

  private

  def millennial(apid, auid)
    url = 'http://ads.mp.mydas.mobi/getAd.php5' +
        "?apid=#{CGI::escape(apid)}" +
        "&auid=#{CGI::escape(auid)}" +
        "&uip=#{get_ip_address_local}" +
        "&ua=#{USER_AGENT}"

    content = Downloader.get(url)

    @tapjoy_ad = TapjoyAd.new

    if /^<\?xml/.match(content)
      doc =  XML::Parser.string(content).parse

      click_url = doc.find('//ad/clickUrl').first.content
      image_url = doc.find('//ad/image/url').first.content
      if image_url.empty?
        no_ad
        return
      end
      image = download_image image_url

      @tapjoy_ad.click_url = click_url
      @tapjoy_ad.image = image

    elsif /^GIF/.match(content)
      logger.info "gif image"
      no_ad
    elsif /^<link/.match(content)
      logger.info "rich media ad"
      doc = Hpricot.parse(content)
      link = (doc/"a").first["href"]
      image_url = (doc/"img").first["src"]
      image = download_image image_url

      @tapjoy_ad.click_url = link
      @tapjoy_ad.image = image
      #@tapjoy_ad.open_in = "Webview"

      #set tracking data for millennial
      tracker_url = (doc/"img")[1]["src"]
      Downloader.get(tracker_url)
    else
      logger.info "html ad"
      #@tapjoy_ad.ad_html = content
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
        "&clientip=#{get_ip_address_local}"

    json_string = Downloader.get(url)
    json = JSON.parse(json_string).first

    if !json or json.length == 0
      logger.info "empty json"
      no_ad
    else
      @tapjoy_ad = TapjoyAd.new

      if json['ad_type'] == 1
        @tapjoy_ad.click_url = json['landing_url']
        @tapjoy_ad.image = download_image json['img_url']
      elsif json['ad_type'] == 2
        #TODO: draw text and image
        #@tapjoy_ad.click_url = json['landing_url']
        logger.info "Type 2 ad not yet implemented"
        no_ad
        return
      elsif json['ad_type'] == 3
        #@tapjoy_ad.ad_html = json['ad_text']
        logger.info "html ad"
        no_ad
        return
      end

      @tapjoy_ad.open_in = json['launch_type'] == 2 ? 'Webview' : 'Safari'
    end
  end

  def adfonic(slot_id)
    url = "http://adfonic.net/ad/#{CGI::escape(slot_id)}" +
        "?r.ip=#{get_ip_address_local}" +
        "&r.id=#{CGI::escape(params[:udid])}" +
        "&test=0" +
        "&t.format=json" +
        "&t.markup=0" +
        "&h.user-agent=#{USER_AGENT}"

    json_string = Downloader.get(url)

    json = JSON.parse(json_string)

    if !json or json['status'] == 'error'
      logger.info "Ad network reported an error"
      no_ad
    else
      @tapjoy_ad = TapjoyAd.new
      @tapjoy_ad.click_url = json['destination']['url']
      if json['components']['image']
        image_url = json['components']['image']['url']
        image = download_image image_url
      else
        text = json['components']['text']['content']
        image = Mc.get_and_put("img.#{text.hash}") do
          start_time = Time.now
          image_array = Magick::Image.read("caption:#{text}") do
            self.size = "320x50"
            self.pointsize = 18
            self.font = 'times'
            self.antialias = true
            self.stroke_width = 1
            self.gravity = Magick::CenterGravity
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

      @tapjoy_ad.image = image
    end
  end

  def crisp(partner_key, site_key, zone_key)
    url = "http://test-api.crispwireless.com/adRequest.v1/single/ad.json" +
        "?partnerkey=#{CGI::escape(partner_key)}" +
        "&sitekey=#{CGI::escape(site_key)}" +
        "&random=#{rand(9999999)}" +
        "&rspid=" +
        "&zonekey=#{CGI::escape(zone_key)}" +
        "&sectionkey=home"

    json_string = Downloader.get(url, {:headers => {'User-Agent' => request.headers['User-Agent']}})

    json = JSON.parse(json_string)

    if !json or !json['html']
      no_ad
    elsif json['clickURL'] && json['clickURL'] != '' && json['mediaSourceURL'] != ''
      @tapjoy_ad = TapjoyAd.new
      @tapjoy_ad.click_url = json['clickURL'].split(' ',2)[0].chop
      Rails.logger.info "Crisp click url: #{@tapjoy_ad.click_url}"
      image_url = json['mediaSourceURL']
      @tapjoy_ad.image = download_image(image_url) if image_url
      @tapjoy_ad.open_in = "Safari"
      @tapjoy_ad.game_id = nil
    else
      @tapjoy_ad = TapjoyAd.new
      @tapjoy_ad.ad_html = json['html']
      @tapjoy_ad.open_in = "Safari"
    end
  end

  def socialreach
    num = rand(6) + 6251 # 6521 <= num <= 6256

    @tapjoy_ad = TapjoyAd.new
    @tapjoy_ad.open_in = 'Webview'
    @tapjoy_ad.click_url = "http://clicks.socialreach.com/click?zone=#{num}"

    image_name = "socialreach-#{num}.jpg"

    image = Mc.get_and_put("img.s3.#{image_name.hash}") do
      bucket = S3.bucket(BucketNames::ADIMAGES)
      image_content = bucket.get(image_name)
      Base64.encode64 image_content
    end

    @tapjoy_ad.image = image
  end

  def publisher_ad(ad_id)
    ad = PublisherAd.new(:key => ad_id)

    if (not ad.get('url'))
      no_ad
      return
    end

    #todo daily/global limits???

    @tapjoy_ad = TapjoyAd.new

    url = ad.get('url')
    open_in = ad.get('open_in')
    open_in = 'Safari' if open_in.nil?

    app_id_to_advertise = ad.get('app_id_to_advertise')

    if app_id_to_advertise
      #todo is it installed??
      open_in = 'Safari'
      #@tapjoy_ad.game_id = app_id_to_advertise
    end

    @tapjoy_ad.open_in = open_in
    @tapjoy_ad.click_url = url
    @tapjoy_ad.ad_id = ad_id

    image = Mc.get_and_put("img.s3.#{ad_id}") do
      bucket = S3.bucket(BucketNames::PUBLISHER_ADS)
      image_content = bucket.get("base64.#{ad_id}")
    end

    @tapjoy_ad.image = image
    @tapjoy_ad.ad_impression_id = params[:campaign_id]
  end

  private
  def get_ip_address_local
    ip_address = get_ip_address
    if ip_address == '127.0.0.1'
      ip_address = '72.164.173.18'
    end
    return ip_address
  end

  def download_image(image_url)
    Mc.get_and_put("img.#{image_url.hash}") do
      Base64.encode64(Downloader.get(image_url))
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
