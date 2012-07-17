# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def sdk_link(text, sdk_type)
    concat(link_to(text, popup_sdk_index_path(:sdk => sdk_type), :rel => 'facebox'))
  end

  def encrypt_url(url)
    ObjectEncryptor.encrypt_url(url)
  end

  def options_for_prerequisites(offer)
    offer.partner.offers.sort { |a, b| a.name <=> b.name }.reject { |o| o.id == offer.id }.collect { |o| [ "#{o.name} -#{o.name_suffix}-#{o.item_type}", o.id ] }
  end

  def options_for_prerequisites_with_app_offer_first(app, offer)
    ([ app.primary_offer ] + app.partner.offers.sort { |a, b| a.name <=> b.name }.reject { |o| o.id == offer.primary_offer.id || o.id == app.primary_offer.id }).collect { |o| [ "#{o.name} -#{o.name_suffix}-#{o.item_type}", o.id ] }
  end
end
