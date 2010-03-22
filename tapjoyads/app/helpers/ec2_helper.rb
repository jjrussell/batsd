require 'right_aws'

module Ec2Helper
  ##
  # Returns an array of the public dns names of all running EC2 servers.
  # If the group_id is specified, then only servers within that security group are returned.
  def get_dns_names(group_id = nil)
    get_server_field(:dns_name, group_id)
  end  
  
  ##
  # Returns an array of the local/private dns names of all running EC2 servers.
  # If the group_id is specified, then only servers withing that security group are returned.
  # Not to be used. Our servers are now set up without internal dns.
  #def get_local_dns_names(group_id = nil)
  #  get_server_field('privateDnsName', group_id)
  #end
  
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
    ec2 = RightAws::Ec2.new(nil, nil, :logger => Logger.new(STDERR))

    instances = ec2.describe_instances
    dns_names = []

    instances.each do |instance|
      if instance[:aws_state] == 'running' and instance[:aws_groups].include?(group_id)
        dns_names.push(instance[field_name])
      end
    end

    return dns_names
  end
end