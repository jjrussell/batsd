namespace :db do
  desc 'Migrate and cache all versioned records.'
  task :migrate do
    if Rails.env == 'production'
      Mc.cache_all
      OfferCacher.cache_offers
    end
  end
end