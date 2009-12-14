class CompleteOfferController < ApplicationController
  def index
    return unless verify_params([:offerid, :app_id, :udid, :url])

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
  
    # TODO: verify url. Add signature to url? Whitelist certain urls?
    redirect_to params[:url]
  end
end