class OneOffs
  def self.change_generic_offer_category_to_non_native_video
    GenericOffer.all.each do |o|
      o.category = 'Non-Native Video' if o.category == 'Video'
      o.category = nil if o.category.blank?
      o.category = 'Non-Native Video' if o.url =~ /youtube\.com/
      o.save(false)
    end
  end
end
