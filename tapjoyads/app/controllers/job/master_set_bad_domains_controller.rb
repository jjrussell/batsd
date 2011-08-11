class Job::MasterSetBadDomainsController < Job::JobController
  
  def index
    now         = Time.zone.now
    earlier     = now - 10.minutes
    mc_key      = 'failed_sdb_saves.web_request_failures'
    now_key     = (now.to_f / 10.minutes).to_i
    earlier_key = (earlier.to_f / 10.minutes).to_i
    date        = now.to_s(:yyyy_mm_dd)
    failures    = {}
    
    MAX_WEB_REQUEST_DOMAINS.times do |num|
      domain_name = "web-request-#{date}-#{num}"
      count = Mc.get_count("failed_sdb_saves.wr.#{domain_name}.#{now_key}")
      count += Mc.get_count("failed_sdb_saves.wr.#{domain_name}.#{earlier_key}")
      failures[domain_name] = count
    end
    
    Mc.put(mc_key, failures)
    
    render :text => 'ok'
  end
  
end
