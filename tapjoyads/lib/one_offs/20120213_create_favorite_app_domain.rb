class OneOffs

  def self.create_favorite_app_domain
    SimpledbResource.create_domain("favorite_apps")
  end

end
