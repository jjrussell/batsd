class CompleteOfferController < ApplicationController
  def index

    if ( (not params[:offerid]) || (not params[:app_id]) || (not params[:udid]) || (not params[:url]))
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'adshown')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
    now = Time.now.utc    
    
    click = OfferClick.new( UUIDTools::UUID.random_create.to_s)
    click.put("click_date", "#{now.to_f.to_s}")
    click.put('offer_id', params[:offerid])
    click.put('app_id', params[:app_id])
    click.put('udid', params[:udid])
    click.put('record_id', params[:record_id])
    click.put('source', 'email')
    click.put('ip_address', request.remote_ip)
    click.save
  
    redirect_to params[:url]
    
  end
end