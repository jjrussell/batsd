module Tools::OfferIconsHelper
  def has_icon
    @has_icon ||= @offer.icon_id_override? && @offer.uploaded_icon?
  end
end
