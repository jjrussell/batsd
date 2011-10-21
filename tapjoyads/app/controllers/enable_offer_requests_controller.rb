class EnableOfferRequestsController < WebsiteController
  include WebsiteHelper

  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create ]

  def create
    offer = Offer.find_by_id(params[:enable_offer_request][:offer_id])
    enable_request = EnableOfferRequest.new
    log_activity(enable_request)
    enable_request.offer = offer
    enable_request.requested_by = current_user
    if enable_request.save
      flash[:notice] = "Your request has been submitted."
    else
      flash[:error] = "This app #{enable_request.errors.first[1]}."
    end
    redirect_to url_to_offer_item(offer)
  end

end
