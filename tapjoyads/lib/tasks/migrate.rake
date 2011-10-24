namespace :db do
  desc 'Migrate and cache all versioned records.'
  task :migrate do
    SCHEMA_VERSION = ActiveRecord::Migrator.current_version
    if Rails.env.production?
      threads = []
      Mc::MEMCACHED_ACTIVE_RECORD_MODELS.each do |model|
        t = Thread.new do
          system("#{Rails.root}/script/runner -e #{Rails.env} '#{model}.cache_all'")
        end
        threads << t
      end
      OfferCacher.cache_offers
      threads.each { |t| t.join }
    end
  end
end
