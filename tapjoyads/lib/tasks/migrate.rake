namespace :db do
  desc 'Migrate and cache all versioned records.'
  task :migrate do
    Mc.cache_all
    Offer.cache_offers
  end
end