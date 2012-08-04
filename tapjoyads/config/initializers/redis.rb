if Rails.env.production?
  $redis = Redis.new(:host => 'redis.tapjoy.net')
  $redis_read = Redis.new(:host => 'alpha.redis.tapjoy.net')
else
  $redis_read = $redis = Redis.new
end
