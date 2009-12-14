class AdshownController < ApplicationController
  def index
    if (not params[:campaign_id]) || (not params[:app_id]) || (not params[:udid])
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'adshown')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
    web_request = WebRequest.new('adshown')
    web_request.put('campaign_id', params[:campaign_id])
    web_request.put('app_id', params[:app_id])
    web_request.put('udid', params[:udid])
    #web_request.put('slot_id', params[:slot_id])
    web_request.put('ip_address', request.remote_ip)
    
    web_request.save

    render :template => 'layouts/success'
  end
end