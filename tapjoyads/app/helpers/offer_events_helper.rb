module OfferEventsHelper
  def offer_event_changes(offer_event)
    OfferEvent::CHANGEABLE_ATTRIBUTES.reject { |attribute| offer_event.send(attribute).nil? }.collect { |attribute|
      if attribute == :daily_budget
        daily_budget = offer_event.send(attribute)
        'daily_budget: ' + (daily_budget == 0 ? 'unlimited' : daily_budget.to_s)
      else
        "#{attribute}: #{offer_event.send(attribute)}"
      end
    }.join("<br/>")
  end
end
