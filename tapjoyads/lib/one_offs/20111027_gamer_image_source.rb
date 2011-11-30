class OneOffs
  def self.update_gamer_image_source
    Gamer.connection.execute("update gamers set image_source = #{Gamer::IMAGE_SOURCE_FACEBOOK} where exists (select 1 from gamer_profiles where gamer_id = gamers.id and facebook_id is not null)")
  end
end
