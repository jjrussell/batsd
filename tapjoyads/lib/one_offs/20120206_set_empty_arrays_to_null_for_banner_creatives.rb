class OneOffs
  def self.set_empty_arrays_to_null_for_banner_creatives
    Offer.update_all("banner_creatives = NULL", 'banner_creatives == "--- []\n\n"')
    Offer.update_all("approved_banner_creatives = NULL", 'approved_banner_creatives == "--- []\n\n"')
  end
end
