class RegisterServersJob
  include Ec2Helper
  
  def run
    dns_names = []
    if ENV['RAILS_ENV'] == 'production'
      dns_names = get_dns_names('webserver') | get_dns_names('jobserver')
    elsif ENV['RAILS_ENV'] == 'testing'
      dns_names = get_dns_names('testserver')
    else
      dns_names = ['127.0.0.1']
    end
    
    Rails.logger.info("RegisterServersJob: registering on machines: #{dns_names}")
    
    dns_names.each do |dns_name|
      sess = Patron::Session.new
      sess.base_url = 'http://localhost:3000'
    
      sess.username = 'internal'
      sess.password = AuthenticationHelper::USERS[sess.username]
      sess.auth_type = :digest
    
      sess.get("/register_server?server=#{dns_name}")
    end
  end
end