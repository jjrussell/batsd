require 'lazy_init_proxy'

if Rails.env.production?
  $redis       = LazyInitProxy.new { Redis.new(:host => 'redis.tapjoy.net') }
  $perma_redis = LazyInitProxy.new { Redis.new(:host => 'redis.tapjoy.net', :db => 1) }
  $redis_read  = LazyInitProxy.new { Redis.new(:host => 'alpha.redis.tapjoy.net') }
else
  $redis_read = $redis = LazyInitProxy.new { Redis.new }
  $perma_redis         = LazyInitProxy.new { Redis.new(:db => 1)}
end

# Collection of connections to do things like reset after forking
$redis_connections = [ $redis, $perma_redis, $redis_read]