class FavoriteApp < SimpledbResource
  self.key_format = 'gamer_id'
  self.domain_name = 'favorite_apps'

  self.sdb_attr :app_ids, :force_array => true, :replace => false
end
