module Ec2Helper
  ##
  # Returns an array of the dns_names of all running EC2 servers.
  def get_dns_names
    ec2 = AWS::EC2::Base.new({:access_key_id => ENV['AMAZON_ACCESS_KEY_ID'], 
        :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']})
    
    instances = ec2.describe_instances
    dns_names = []
    
    instances['reservationSet']['item'].each do |item|
      if item['instancesSet']['item'][0]['instanceState']['name'] == 'running'
        dns_names.push(item['instancesSet']['item'][0]['dnsName'])
      end
    end
    return dns_names
  end
end