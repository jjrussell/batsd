class FavoriteApp < SimpledbShardedResource
  belongs_to :gamer
  belongs_to :app

  self.key_format = 'gamer_id.app_id'

  self.sdb_attr :gamer_id
  self.sdb_attr :app_id

  self.num_domains = NUM_FAVORITE_APP_DOMAINS

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_FAVORITE_APP_DOMAINS
    "favorite_apps_#{domain_number}"
  end

  def initialize(options = {})
    super({ :load_from_memcache => false }.merge(options))
  end

  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end

  def self.add_favorite_app(gamer_id, app_id)
    fav_app = FavoriteApp.new(:key => "#{gamer_id}.#{app_id}", :consistent => true)
    return unless fav_app.new_record?
    fav_app.gamer_id = gamer_id
    fav_app.app_id = app_id
    fav_app.save
  end

  def self.delete_favorite_app(gamer_id, app_id)
    fav_app = FavoriteApp.new(:key => "#{gamer_id}.#{app_id}", :consistent => true)
    fav_app.delete_all unless fav_app.new_record?
  end
end
