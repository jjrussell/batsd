module Dashboard::OfferHelper
  def offer_title_for(offer)
    "#{offer.name} [#{offer_title_suffix_for(offer)}]"
  end

  def offer_title_suffix_for(offer)
    if offer.main? && offer.rewarded && !offer.featured?
      'Main'
    elsif offer.main?
      "Main #{offer_type_description_for(offer)}"
    else
      offer.name_suffix
    end
  end

  def offer_type_description_for(offer)
    (offer.rewarded? ? 'rewarded'  : 'non-rewarded') +
    (offer.featured? ? ' featured' : '')
  end
end
