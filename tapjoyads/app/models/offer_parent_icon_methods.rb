module OfferParentIconMethods

  def get_icon_url(options = {})
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(id)}.merge(options))
  end

  def save_icon!(icon_src_blob)
    Offer.upload_icon!(icon_src_blob, id, self.class.name == 'VideoOffer')
  end

end
