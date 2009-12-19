class Reward < SimpledbResource
  def initialize(key = nil, options = {})
    key = UUIDTools::UUID.random_create.to_s unless key
    super 'reward', key, options
    put('created', Time.now.utc.to_f.to_s) unless get('created')
  end
  
  def update_counters
    # increment our memcached counters
    if get('type') != 'rating'
      increment_count_in_cache(
        WebRequest.get_memcache_count_key('rewards_revenue', get('publisher_app_id'), Time.at(get('created').to_f)), 
        false, 1.week, reward.get('publisher_amount').to_i)
    end
    
    case get('type')
    when 'install'
      increment_count_in_cache(
        WebRequest.get_memcache_count_key('installs_revenue', get('publisher_app_id'), Time.at(get('created').to_f)), 
        false, 1.week, reward.get('publisher_amount').to_i)
        
      increment_count_in_cache(
        WebRequest.get_memcache_count_key('installs_spend', get('advertiser_app_id'), Time.at(get('created').to_f)), 
        false, 1.week, reward.get('advertiser_amount').to_i)
    when 'offer'
      increment_count_in_cache(
        WebRequest.get_memcache_count_key('offers_revenue', get('publisher_app_id'), Time.at(get('created').to_f)), 
        false, 1.week, reward.get('publisher_amount').to_i)      
    end
    

  end
  
  
  
end