require 'spec_helper'

describe Job::MasterTerminateSlowInstancesController do
  describe '#index' do
    before :each do
      @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    end

    it "does nothing with no params" do
      get(:index)
    end
  end

  describe 'find_slow' do
    before :each do
      @i_fast1_running = {:aws_instance_id => 'i-7473847', :private_dns_name => 'ip-12-1-123-8', :aws_state => 'running' }
      @i_fast2_running = {:aws_instance_id => 'i-385829', :private_dns_name => 'ip-19-182-123-7', :aws_state => 'running' }
      @i_fast3_running = {:aws_instance_id => 'i-48548309', :private_dns_name => 'ip-112-182-13-8', :aws_state => 'running' }
      @i_fast4_pending = {:aws_instance_id => 'i-8859823', :private_dns_name => 'ip-214-2-13-8', :aws_state => 'pending' }
      @i_fast5_shutdown = {:aws_instance_id => 'i-45728459', :private_dns_name => 'ip-114-90-13-8', :aws_state => 'shutdown' }
      @i_slow1_running = {:aws_instance_id => 'i-1338472', :private_dns_name => 'domU-9-82-13-8', :aws_state => 'running' }
      @i_slow2_pending = {:aws_instance_id => 'i-193848', :private_dns_name => 'domU-3-82-13-4', :aws_state => 'pending' }
      @i_slow3_running = {:aws_instance_id => 'i-65450', :private_dns_name => 'domU-88-82-18-9', :aws_state => 'running' }
      @i_slow4_shutdown = {:aws_instance_id => 'i-9558394', :private_dns_name => 'domU-13-83-13-8', :aws_state => 'shutdown' }
      @i_slow5_running = {:aws_instance_id => 'i-5729348', :private_dns_name => 'domU-107-62-13-8', :aws_state => 'running' }
    end

    it "finds only slow instances that are running" do
      @instances = [@i_slow2_pending, @i_slow4_shutdown, @i_fast1_running, @i_fast2_running, @i_fast3_running, @i_fast4_pending, @i_fast5_shutdown]
      @controller.send(:find_slow, @instances).should be_nil
    end

    it "returns the first slow instance" do
      @instances = [@i_slow2_pending, @i_slow4_shutdown, @i_slow1_running, @i_fast2_running, @i_fast3_running, @i_slow3_running, @i_fast4_pending, @i_fast5_shutdown]
      @controller.send(:find_slow, @instances).should == @i_slow1_running[:aws_instance_id]
      @instances = [@i_slow2_pending, @i_slow4_shutdown, @i_slow5_running, @i_fast2_running, @i_fast3_running, @i_slow3_running, @i_fast4_pending, @i_fast5_shutdown]
      @controller.send(:find_slow, @instances).should == @i_slow5_running[:aws_instance_id]
    end
  end

  describe 'terminate_slow' do
    it "will call terminate on an instance_id" do
      @mock = 'mockit'
      @controller.should_receive(:as_interface).and_return(@mock)
      @mock.should_receive(:terminate_instance_in_auto_scaling_group).with('i-whatever', false)
      @controller.send(:terminate_slow, 'i-whatever')
    end

    it "will do nothing if no instance is passed in" do
      @controller.should_not_receive(:as_interface)
      @controller.send(:terminate_slow, nil)
    end
  end
end
