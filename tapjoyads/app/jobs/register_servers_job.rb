class RegisterServersJob
  include Ec2Helper
  
  def run(run_mode = nil)
    run_mode ||= ENV['RAILS_ENV']
    
    dns_names = []
    base_url = ''
    if run_mode == 'production'
      dns_names = get_dns_names('webserver') | get_dns_names('jobserver')
      base_url = 'http://localhost:9898'
    elsif run_mode == 'test'
      dns_names = get_dns_names('testserver')
      base_url = 'http://localhost:9898'
    else
      dns_names = ['127.0.0.1']
      base_url = 'http://localhost:3000'
    end
    
    Rails.logger.info("RegisterServersJob: registering on machines: #{dns_names}")
    
    sess = Patron::Session.new
    sess.base_url = base_url
    
    sess.timeout = 60
    
    sess.username = 'internal'
    sess.password = AuthenticationHelper::USERS[sess.username]
    sess.auth_type = :digest
  
    sess.get("/register_server?servers=#{dns_names.join(',')}")
  end
end