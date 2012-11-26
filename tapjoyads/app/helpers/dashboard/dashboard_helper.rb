module Dashboard::DashboardHelper
  def offer_type_for(opts=nil)
    return nil unless opts
    (opts[:rewarded] ? 'rewarded'  : 'non_rewarded') +
    (opts[:featured] ? '_featured' : '')
  end

  def nav_item_title_for(opts)
    (opts[:rewarded] ? 'Rewarded '  : 'Non-Rewarded ') +
    (opts[:featured] ? 'Featured ' : '') +
    'Installs'
  end

  def nav_item_selected?(offer, opts)
    controller_name == 'offers' &&
    (
      (offer.rewarded? == opts[:rewarded] && offer.featured? == opts[:featured]) ||
      params[:offer_type] == offer_type_for(opts)
    )
  end

  def css_classes_for_nav_item(offer, opts)
    [
      nav_item_selected?(offer, opts) ? 'selected' : '',
      offer.main? ? 'main' : 'non_main'
    ]
  end

  def scheduled_selected?(offer)
    controller_name == 'offer_events' && offer.main?
  end

  def css_selected_class_for_scheduled(offer)
    scheduled_selected?(offer) ? 'selected' : ''
  end

end
