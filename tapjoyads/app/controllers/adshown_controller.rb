class AdshownController < ApplicationController
  def index
    return unless verify_params([:campaign_id, :app_id, :udid])
    
    web_request = WebRequest.new('adshown', params, request)
    web_request.save

    render :template => 'layouts/success'
  end
end