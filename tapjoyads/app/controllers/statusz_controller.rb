class StatuszController < ApplicationController
  include AuthenticationHelper
  include MemcachedHelper

  before_filter 'authenticate'
  
  def index
    @install_count_24hours = get_from_cache('statusz.install_count_24hours')
    @app_list = get_from_cache('statusz.app_list')
    @appstats_list = get_from_cache('statusz.appstats_list')
    @last_updated = get_from_cache('statusz.last_updated')
    
    if params[:reload] != '1' and @install_count_24hours and @app_list and @appstats_list and @last_updated
      return
    end
    
    @install_count_24hours = StoreClick.count(:where => "installed > '#{Time.now.to_f - 1.day}'")

    @app_list = []
    App.select(:where => "interval_update_time = '3600'") do |app|
      @app_list.push(app)
    end

    now = Time.now.utc
    
    @appstats_list = []
    @app_list.each do |app|
      @appstats_list.push(Appstats.new(app.key, {
        :stat_types => ['paid_installs', 'paid_clicks', 'logins', 'new_users', 'published_installs', 'installs_opened', 'hourly_impressions'],
        :start_time => now - 23.hours,
        :end_time => now + 1.hour}))
    end

    @last_updated = Time.now
    
    save_to_cache('statusz.install_count_24hours', @install_count_24hours)
    save_to_cache('statusz.app_list', @app_list)
    save_to_cache('statusz.appstats_list', @appstats_list)
    save_to_cache('statusz.last_updated', @last_updated)
  end
end
