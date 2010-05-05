class StatzController < WebsiteController
  include MemcachedHelper
  
  filter_access_to [ :index ]
  
  def index
    @install_count_24hours = get_from_cache('statz.install_count_24hours')
    @last_updated = get_from_cache('statz.last_updated')
    @appstats_hash = {}
    
    @app_list = []
    SdbApp.select(:where => "interval_update_time = '3600'") do |app|
      @app_list.push(app)
    end
    
    @app_list.each do |app|
      @appstats_hash[app.key] = get_from_cache("statz.appstats.#{app.key}")
    end
  end
end
