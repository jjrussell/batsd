module PartnersHelper
  def link_to_offer(offer)
    if permitted_to?(:show, :statz)
      link_to(offer.name_with_suffix, statz_path(offer.id))
    else
      offer.name_with_suffix
    end
  end
end
