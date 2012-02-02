class OneOffs

  def self.create_favorite_app_domains
    NUM_FAVORITE_APP_DOMAINS.times do |i|
      SimpledbResource.create_domain("favorite_apps_#{i}")
    end
  end

end
