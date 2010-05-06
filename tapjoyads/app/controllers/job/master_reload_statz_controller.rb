class Job::MasterReloadStatzController < Job::JobController
  include MemcachedHelper
  
  def index
    cached_stats = {}
    
    apps = []
    SdbApp.select(:where => "interval_update_time = '3600'") do |app|
      apps.push(app)
    end

    apps.each do |app|
      appstats = Appstats.new(app.key, { :start_time => now - 23.hours, :end_time => now + 1.hour })
      
      this_apps_stats = {}
      this_apps_stats['icon_url'] = app.get_icon_url
      this_apps_stats['app_name'] = app.name
      this_apps_stats['paid_installs'] = appstats['paid_installs'].sum
      this_apps_stats['connects'] = appstats['logins'].sum
      this_apps_stats['new_users'] = appstats['new_users'].sum
      this_apps_stats['daily_active_users'] = appstats['daily_active_users'].sum
      this_apps_stats['price'] = number_to_currency(app.price / 100.0)
      this_apps_stats['payment_for_install'] = number_to_currency(app.payment_for_install / 100.0)
      this_apps_stats['balance'] = number_to_currency(app.balance / 100.0)
      this_apps_stats['daily_budget'] = app.daily_budget
      this_apps_stats['show_rate'] = "%.2f" % app.show_rate
      this_apps_stats['vg_purchases'] = appstats['vg_purchases'].sum
      this_apps_stats['published_installs'] = appstats['published_installs'].sum
      this_apps_stats['installs_revenue'] = number_to_currency(appstats['installs_revenue'].sum / 100.0)
      this_apps_stats['ad_impressions'] = appstats['hourly_impressions'].sum
      
      cached_stats[app.key] = this_apps_stats
    end

    save_to_cache('statz.cached_stats', cached_stats)

    install_count_24hours = StoreClick.count(:where => "installed > '#{Time.now.to_f - 1.day}'")
    save_to_cache('statz.install_count_24hours', install_count_24hours)
    
    save_to_cache('statz.last_updated', Time.zone.now)
    
    render :text => 'ok'
  end
  
end