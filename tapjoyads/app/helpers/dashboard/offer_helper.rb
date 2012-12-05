module Dashboard::OfferHelper
  def offer_title_for(offer)
    "#{offer.name} #{offer_title_suffix_for(offer)}"
  end

  def offer_title_suffix_for(offer)
    offer_suffix_for(offer) + main_offer_description_for(offer)
  end

  def offer_suffix_for(offer)
    offer.name_suffix.present? ? "(#{offer.name_suffix})" : ''
  end

  def main_offer_description_for(offer)
    if offer.main?
      if offer.rewarded && !offer.featured?
        ' [Main]'
      else
        " [Main #{offer_type_description_for(offer)}]"
      end
    else
      ''
    end

  end

  def offer_type_description_for(offer)
    (offer.rewarded? ? 'rewarded'  : 'non-rewarded') +
    (offer.featured? ? ' featured' : '')
  end
end
