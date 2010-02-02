class StatuszController < ApplicationController
  include AuthenticationHelper
  include MemcachedHelper

  before_filter 'authenticate'
  
  def index
    @install_count_24hours = StoreClick.count(:where => "installed > '#{Time.now.to_f - 1.day}'")
    
    json_string = get_from_cache_and_save("s3.offer-data.rewarded_installs_list") do
      bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
      bucket.get('rewarded_installs_list')
    end
    serialized_advertiser_app_list = JSON.parse(json_string)
    @app_list = []
    serialized_advertiser_app_list.each do |serialized_advertiser_app|
      @app_list.push(App.deserialize(serialized_advertiser_app))
    end
    
    #@app_list = @app_list[0,5]
    
    now = Time.now.utc
    
    @appstats_list = []
    @app_list.each do |app|
      @appstats_list.push(Appstats.new(app.key, {
        :stat_types => ['paid_installs', 'paid_clicks', 'logins', 'new_users'],
        :start_time => now - 24.hours,
        :end_time => now}))
    end
    
  end
end
