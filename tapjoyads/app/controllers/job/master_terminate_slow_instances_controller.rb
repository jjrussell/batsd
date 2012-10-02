class Job::MasterTerminateSlowInstancesController < Job::JobController

  # Search for slow instances for the specified group.
  # Terminate one of the running slow ones.
  # Space out calls to this controller as required.
  def index
    if params[:group_name]
      instances = ec2_interface.describe_instances(:filters => {'group-name' => params[:group_name]})
      terminate_slow find_slow(instances)
    end

    render :text => 'ok'
  end

  private

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
