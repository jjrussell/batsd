if Rails.env.production?
  REDIS = Redis.new(:host => 'redis.tapjoy.net', :port => 6379)
else
  REDIS = Redis.new
end
