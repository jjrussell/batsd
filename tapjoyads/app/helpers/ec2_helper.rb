require 'AWS'

module Ec2Helper
  ##
  # Returns an array of the public dns names of all running EC2 servers.
  # If the group_id is specified, then only servers withing that security group are returned.
  def get_dns_names(group_id = nil)
    get_server_field('dnsName', group_id)
  end  
  
  ##
  # Returns an array of the local/private dns names of all running EC2 servers.
  # If the group_id is specified, then only servers withing that security group are returned.
  def get_local_dns_names(group_id = nil)
    get_server_field('privateDnsName', group_id)
  end
  
  def get_server_type
    hostname = `hostname`
    unless hostname =~ /^ip-|^domU-/
      # This is not an amazon instance.
      return 'dev'
    end

    security_groups = `curl -s http://169.254.169.254/latest/meta-data/security-groups`.split("\n")
    if security_groups.include? 'testserver'
      machine_type = 'test'
    elsif security_groups.include? 'jobserver'
      machine_type = 'jobs'
    elsif security_groups.include? 'masterjobs'
      machine_type = 'masterjobs'
    else
      machine_type = 'web'
    end

    return machine_type
  end
  
  private
  
  def get_server_field(field_name, group_id)
    ec2 = AWS::EC2::Base.new({:access_key_id => ENV['AWS_ACCESS_KEY_ID'], 
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']})

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
        dns_names.push(item['instancesSet']['item'][0][field_name])
      end
    end
    return dns_names
  end
end