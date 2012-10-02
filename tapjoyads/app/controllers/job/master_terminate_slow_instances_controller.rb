#class Job::MasterTerminateSlowInstancesController < Job::JobController
class Job::MasterTerminateSlowInstancesController < ApplicationController

  def webserver
    find_and_terminate_slow({'group-name' => 'webserver'})
    render :text => 'ok'
  end

  private

  # Load all instances, search for "slow" ones.
  # Terminate one of them.
  # Space out calls to this controller as required.
  def find_and_terminate_slow(filters)
    instances = ec2_interface.describe_instances :filters => filters
    terminate_slow find_slow(instances)
  end

  def find_slow(instances)
    slow_ones = instances.reject{|i| !i[:private_dns_name].start_with?('domU-') || i[:aws_state] != 'running'}
    slow_ones && !slow_ones.empty? ? slow_ones.first[:aws_instance_id] : nil
  end

  def terminate_slow(instance_id)
    if instance_id
      as_interface.terminate_instance_in_auto_scaling_group(instance_id, false)
    end
  end

  def ec2_interface
    RightAws::Ec2.new
  end

  def as_interface
    RightAws::AsInterface.new
  end
end
