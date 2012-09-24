module OfferParentIconMethods

  def get_icon_url(options = {})
    return app_primary_app_metadata.get_icon_url(options) if app_primary_app_metadata.present?
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(id)}.merge(options))
  end

  def save_icon!(icon_src_blob)
    return app_primary_app_metadata.save_icon!(icon_src_blob) if app_primary_app_metadata.present?
    return unless Offer.upload_icon!(icon_src_blob, id, self.class.name == 'VideoOffer')
    offers.each do |offer|
      offer.remove_icon! if offer.auto_update_icon?
    end
  end

  private

  def app_primary_app_metadata
    if respond_to?(:primary_app_metadata)
      return primary_app_metadata
    elsif respond_to?(:app)
      return app.primary_app_metadata
    end
    nil
  end

end
