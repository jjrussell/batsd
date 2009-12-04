class Service1Controller < ApplicationController
  
  before_filter :redirect
  
  private
    def redirect
      ruby_lb = REDIRECT_URI
      win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/Service1.asmx'
      
      standard_params = "?udid=#{get_param(:DeviceTag, true)}&app_id=#{get_param(:AppID, true)}" +
        "&device_type=#{get_param(:DeviceType)}&app_version=#{get_param(:AppVersion)}" +
        "&library_version=#{get_param(:ConnectLibraryVersion)}" +
        "&device_os_version=#{get_param(:DeviceOSVersion)}"
      
      url = case params[:action]

      when 'GetTapjoyAd'
        if (get_param(:AdCampaignID, true) == "")
          render :text => "Missing AdCampaignID"
          return
        end
        campaign = Campaign.new(get_param(:AdCampaignID))
        network_name = campaign.get('network_name')
        Rails.logger.info campaign.to_json
        Rails.logger.info "network_name: #{network_name}"
        path = case network_name
        when "Millennial"
          apid = CGI::escape campaign.get('id1')
          auid = CGI::escape campaign.get('id2')
          "millennial" + standard_params + "&apid=#{apid}&auid=#{auid}"
        when "MDotM"
          apikey = ""
          appkey = CGI::escape get_param(:app_id)
          "mdotm" + standard_params + "&apikey=#{apikey}&appkey=#{appkey}"
        when "Adfonic"
          slot_id = CGI::escape campaign.get('id1')
          "adfonic" + standard_params + "&slot_id=#{slot_id}"
        when "Crisp"
          partner_key = CGI::escape campaign.get('id1')
          site_key = CGI::escape campaign.get('id2')
          zone_key = CGI::escape campaign.get('id3')
          "crisp" + standard_params + "&partner_key=#{partner_key}&site_key=#{site_key}&zone_key=#{zone_key}"
        when "SocialReach"
          "socialreach" + standard_params
        when "PublisherAds"
          ad_id = CGI::escape campaign.get('ad_id')
          campaign_id = get_param(:AdCampaignID, true)
          "publisher_ad" + standard_params + "&ad_id=#{ad_id}&campaign_id=#{campaign_id}"
        else
          "socialreach" + standard_params #render :text => "no ad"
          #return
        end
        ruby_lb + "getad/#{path}"
      when 'index'
         win_lb
      else 
        win_lb + "/" + params[:action] + "?" + request.query_string
      end
      
      redirect_to url
    end
    
    def get_param(label, d = false)
      p = params[label]
      return "" unless p
      p = p.downcase if d
      return CGI::escape(p)
    end
    
end
