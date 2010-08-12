class Job::MasterSetBadDomainsController < Job::JobController
  def index
    mc_key = 'failed_sdb_saves.bad_domains'
    bad_domains = Mc.get(mc_key)
    
    now = Time.zone.now
    date = now.strftime('%Y-%m-%d')
    minumum_interval = 5.minutes
    hour_key = ((now - minumum_interval).to_f / 1.hour).to_i
    
    bad_domains.reject! do |key, value|
      value + 2.hours < now
    end
    
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      domain_name = "web-request-#{date}-#{num}"
      count = Mc.get_count("failed_sdb_saves.#{domain_name}.#{hour_key}")
      seconds = (now - minumum_interval).hour == now.hour ? now - now.beginning_of_hour : 1.hour
      fail_rate = count.to_f / seconds
      
      if fail_rate > 0.25 && bad_domains[domain_name].nil?
        bad_domains[domain_name] = now
        Notifier.alert_new_relic(BadWebRequestDomain, 
          "#{domain_name} has been marked bad. #{fail_rate} fails/second over last #{seconds} seconds.",
          request, params)
      end
    end
    
    Mc.put(mc_key, bad_domains)
    
    render :text => 'ok'
  end
end