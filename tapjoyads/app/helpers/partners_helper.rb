module PartnersHelper
  def decrypt_if_permitted(object, field_name)
    if permitted_to?(:payout_info, :tools)
      field_name = [:decrypt, field_name].join('_').to_sym
    end
    object.send(field_name)
  end
end
