if Rails.env.production?
  $redis = Redis.new(:host => 'redis.tapjoy.net', :port => 6379)
else
  $redis = Redis.new
end
