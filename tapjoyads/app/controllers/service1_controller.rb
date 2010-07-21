class Service1Controller < ApplicationController
  
  before_filter :redirect
  
  private
    def redirect
      win_lb = 'http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com/Service1.asmx'
      
      standard_params = "?udid=#{get_param(:DeviceTag, true)}&app_id=#{get_param(:AppID, true)}" +
        "&device_type=#{get_param(:DeviceType)}&app_version=#{get_param(:AppVersion)}" +
        "&library_version=#{get_param(:ConnectLibraryVersion)}" +
        "&device_os_version=#{get_param(:DeviceOSVersion)}"
      
      url = case params[:action]
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
