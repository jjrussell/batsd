namespace :mc do
  desc 'Prime memcached with offer lists and active record objects.'
  task :prime do
    if Rails.env == 'production'
      Mc.cache_all
      Offer.cache_offers
    end
  end
end
