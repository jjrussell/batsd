class AdshownController < ApplicationController
  def index
    return unless verify_params([:campaign_id, :app_id, :udid])
    
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