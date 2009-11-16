# Registers all servers in the 'mc' security group to be in this server's memcache pool.

class Job::RegisterServersController < Job::JobController
  include Ec2Helper
  
  def index
    dns_names = []
    if ENV['RAILS_ENV'] == 'production'
      dns_names = get_local_dns_names('mc')
    elsif ENV['RAILS_ENV'] == 'test'
      dns_names = get_local_dns_names('testserver')
    else
      dns_names = ['127.0.0.1']
    end
    
    CACHE.reset dns_names
    
    render :text => "ok"
  end
end