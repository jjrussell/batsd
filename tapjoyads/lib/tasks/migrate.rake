namespace :db do
  desc 'Migrate and cache all versioned records.'
  task :migrate do
    if Rails.env.production?
      threads = []
      Mc::MEMCACHED_ACTIVE_RECORD_MODELS.each do |model|
        t = Thread.new do
          system("#{Rails.root}/script/runner -e #{Rails.env} '#{model}.cache_all(true)'")
        end
        threads << t
      end
      unless Offer.version_cached?
        RecommendationList.cache_most_popular_offers
        OfferCacher.cache_offers(true)
      end
      threads.each { |t| t.join }
    end
  end
end
