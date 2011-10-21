class Tools::OfferEventsController < OfferEventsController
  current_tab :tools
  
private
  def setup
    @offer_event = OfferEvent.find(params[:id]) if params[:id]
  end
  
  def new_offer_event
    OfferEvent.new
  end
  
  def offer_events_scope
    OfferEvent
  end

end
