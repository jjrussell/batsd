require 'AWS'

module Ec2Helper
  ##
  # Returns an array of the dns_names of all running EC2 servers.
  def get_dns_names(group_id = nil)
    ec2 = AWS::EC2::Base.new({:access_key_id => ENV['AMAZON_ACCESS_KEY_ID'], 
        :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']})
    
    instances = ec2.describe_instances
    dns_names = []
    
    instances['reservationSet']['item'].each do |item|
      instance_state = item['instancesSet']['item'][0]['instanceState']['name']
      
      group_ids = []
      item['groupSet']['item'].each do |h|
        group_ids.push(h['groupId'])
      end
      
      group_id_match = true
      group_id_match = group_ids.include?(group_id) if group_id
      
      if instance_state == 'running' and group_id_match
        dns_names.push(item['instancesSet']['item'][0]['dnsName'])
      end
    end
    return dns_names
  end
end