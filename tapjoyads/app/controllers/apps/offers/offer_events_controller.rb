class Apps::Offers::OfferEventsController < OfferEventsController
  layout 'apps'
  current_tab :apps

private
  def setup
    @app = App.find(params[:app_id])
    @offer = @app.offers.find(params[:offer_id])
    @offer_event = @offer.events.find(params[:id]) if params[:id]
  end

  def new_offer_event
    @offer.events.build
  end

  def offer_events_scope
    @offer.events
  end

end
