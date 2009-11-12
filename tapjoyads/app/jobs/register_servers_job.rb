require 'AWS'

class RegisterServersJob
  def run
    # Only run this job in production mode. All other modes use 127.0.0.1 as their memcache server.
    #unless ENV['RAILS_ENV'] == 'production'
    #  return
    #end
    
    ec2 = AWS::EC2::Base.new({:access_key_id => ENV['AMAZON_ACCESS_KEY_ID'], 
        :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']})
    
    instances = ec2.describe_instances
    dns_names = []
    
    instances['reservationSet']['item'].each do |item|
      if item['instancesSet']['item'][0]['instanceState']['name'] == 'running'
        dns_names.push(item['instancesSet']['item'][0]['dnsName'])
      end
    end
    
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