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
        when 'Connect' then ruby_lb + "connect" + standard_params
        when 'AdShown' then ruby_lb + "adshown" + standard_params + "&campaign_id=#{get_param(:CampaignID, true)}"
        when 'index' then win_lb
        else win_lb + "/" + params[:action] + "?" + request.query_string
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
