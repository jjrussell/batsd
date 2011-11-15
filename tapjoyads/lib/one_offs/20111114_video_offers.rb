class OneOffs

  def self.update_video_offer_name_suffix
    Offer.find_each(:conditions => "item_type = 'VideoOffer' and name_suffix != ''") do |offer|
      offer.update_attribute(:name_suffix, 'Video')
    end
  end

end
