if Rails.env.production?
  $redis = Redis.new(:host => 'redis.tapjoy.net')
  $perma_redis = Redis.new(:host => 'redis.tapjoy.net', :db => 1)
  $redis_read = Redis.new(:host => 'alpha.redis.tapjoy.net')
else
  $redis_read = $redis = Redis.new
end
