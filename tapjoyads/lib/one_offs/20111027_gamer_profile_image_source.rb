class OneOffs
  def self.update_gamer_profile_image_source
    GamerProfile.connection.execute("update gamer_profiles set image_source = 'facebook' where facebook_id is not null")
  end
end
