class OneOffs

  def self.update_video_offer_name_suffix
    VideoOffer.all.map(&:offers).flatten.each do |offer|
      offer.update_attribute(:name_suffix, 'video') if offer.name_suffix.blank?
    end
  end

end
