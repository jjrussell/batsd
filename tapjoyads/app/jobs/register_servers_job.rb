require 'AWS'

class RegisterServersJob
  include Ec2Helper
  
  def run
    # Only run this job in production mode. All other modes use 127.0.0.1 as their memcache server.
    unless ENV['RAILS_ENV'] == 'production'
      return
    end
    
    dns_names = get_dns_names
    
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