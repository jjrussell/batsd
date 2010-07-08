class CompleteOfferController < ApplicationController
  
  def index
    return unless verify_params([:offerid, :app_id, :udid, :url])

    now = Time.now.utc
    
    click = OfferClick.new
    click.put("click_date", "#{now.to_f.to_s}")
    click.put('offer_id', params[:offerid])
    click.put('app_id', params[:app_id])
    click.put('udid', params[:udid])
    click.put('publisher_user_id', params[:publisher_user_id])
    click.put('source', 'email')
    click.put('ip_address', get_ip_address)
    click.save
  
    # TODO: verify url. Add signature to url? Whitelist certain urls?
    redirect_to params[:url]
  end
end