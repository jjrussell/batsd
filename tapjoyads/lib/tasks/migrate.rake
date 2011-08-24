namespace :db do
  desc 'Migrate and cache all versioned records.'
  task :migrate do
    SCHEMA_VERSION = ActiveRecord::Migrator.current_version
    if Rails.env == 'production'
      Mc.cache_all
      OfferCacher.cache_offers
    end
  end
end
