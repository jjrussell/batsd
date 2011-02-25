# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def simple_paragraphs(text)
    text = '' if text.nil?
    start_tag = tag('p', {}, true)
    text = sanitize(text)
    text.gsub!(/\r\n?/, "\n")
    text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1</p><p>')
    text.insert 0, start_tag
    text + "</p>"
  end
  
  def link_to_generated_actions_header(app, name = nil)
    name ||= app.default_actions_file_name
    if app.is_android?
      link_to(name, TapjoyPPA_app_action_offers_path(app, :format => "java"))
    else
      link_to(name, TJCPPA_app_action_offers_path(app, :format => "h"))
    end
  end
  
  def url_to_offer_item(offer)
    if offer.item.is_a? ActionOffer
      edit_app_action_offer_url(offer.item.app, offer.item)
    elsif offer.featured?
      edit_app_featured_offer_url(offer.item, offer)
    else
      app_offer_url(offer.item, offer)
    end
  end
end
