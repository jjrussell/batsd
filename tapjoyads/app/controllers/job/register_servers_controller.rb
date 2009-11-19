# Registers all servers in the 'mc' security group to be in this server's memcache pool.

class Job::RegisterServersController < Job::JobController
  def index
    MemcachedModel.instance.register_servers
    
    render :text => "ok"
  end
end