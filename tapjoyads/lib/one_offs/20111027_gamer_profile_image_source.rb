class OneOffs
  def self.update_gamer_profile_image_source
    GamerProfile.update_all("image_source = 'facebook'", 'facebook_id is not null')
  end
end
