class OneOffs
  def self.update_icon_id_override
    Offer.find_all_by_item_type('DeeplinkOffer').each do |o|
      o.icon_id_override = o.item.app.primary_app_metadata.id if !o.item.app.hidden? && o.item.app.primary_app_metadata.present?
      o.save! if o.icon_id_override_changed?
    end
  end
end
