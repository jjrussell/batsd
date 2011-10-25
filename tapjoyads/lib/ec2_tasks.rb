class Ec2Tasks
  require 'yaml'
  require 'rubygems'
  require 'right_aws'
  require 'lib/extensions/right_elb_interface'

  def self.get_dns_names(group_id)
    get_field_values([ :dns_name ], group_id).collect { |value_hash| value_hash[:dns_name] }
  end

  def self.get_dns_names_with_instance_ids(group_id)
    get_field_values([ :dns_name, :aws_instance_id ], group_id)
  end

  def self.get_field_values(field_names, group_id)
    amazon_credentials = YAML::load_file("#{ENV['HOME']}/.tapjoy_aws_credentials.yaml")
    ENV['AWS_ACCESS_KEY_ID'] = amazon_credentials['production']['access_key_id'] unless ENV['AWS_ACCESS_KEY_ID']
    ENV['AWS_SECRET_ACCESS_KEY'] = amazon_credentials['production']['secret_access_key'] unless ENV['AWS_SECRET_ACCESS_KEY']
    ec2 = RightAws::Ec2.new(nil, nil, :logger => Logger.new(STDERR))

    field_names << :aws_groups
    field_values = []
    ec2.describe_instances.each do |instance|
      if instance[:aws_state] == 'running' && instance[:aws_groups].include?(group_id)
        value_hash = {}
        field_names.each do |field_name|
          value_hash[field_name] = instance[field_name]
        end
        field_values << value_hash
      end
    end
    field_values
  end

  def self.get_elb_interface
    amazon_credentials = YAML::load_file("#{ENV['HOME']}/.tapjoy_aws_credentials.yaml")
    ENV['AWS_ACCESS_KEY_ID'] = amazon_credentials['production']['access_key_id'] unless ENV['AWS_ACCESS_KEY_ID']
    ENV['AWS_SECRET_ACCESS_KEY'] = amazon_credentials['production']['secret_access_key'] unless ENV['AWS_SECRET_ACCESS_KEY']
    RightAws::ElbInterface.new(nil, nil, :logger => Logger.new(STDERR))
  end

end
