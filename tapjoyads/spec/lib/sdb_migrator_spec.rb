require 'spec_helper'

class FakeResource < SimpledbShardedResource
  include SdbMigrator
  new_configuration :new_num_domains => 10, :new_domain_name => "new_fake_resource"

  self.num_domains = NUM_CLICK_DOMAINS

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_CLICK_DOMAINS

    "fake_resource_#{domain_number}"
  end
end

describe SdbMigrator do
  describe 'when included in SimpledbShardedResource class' do
    describe 'the configuration' do
      it 'should specify the new number of domains' do
        FakeResource.new_num_domains.should == 10
      end

      it 'should specify the new domain name' do
        FakeResource.new_domain_name.should == 'new_fake_resource'
      end
    end

    describe 'saving instances' do
      before(:each) do
        @fake_resource = FakeResource.new(:key => "123")
      end
      it 'should only invoke write_to_sdb once' do
        @fake_resource.should_receive(:write_to_sdb).once
        @fake_resource.save
      end

      it 'should end up saving the object twice' do
        @fake_resource.should_receive(:write_to_sdb_without_mirror).twice
        @fake_resource.save
      end

      it 'should save to the current domain and then the new domain' do
        $fake_sdb.should_receive(:put_attributes).with("#{RUN_MODE_PREFIX}fake_resource_1", "123", anything(), anything(), anything()).once
        $fake_sdb.should_receive(:put_attributes).with("new_fake_resource_5", "123", anything(), anything(), anything()).once
        @fake_resource.save!
      end

      it 'should not save to the new domain if saving to the current domain fails' do
        $fake_sdb.should_receive(:put_attributes).with("#{RUN_MODE_PREFIX}fake_resource_1", "123", anything(), anything(), anything()).and_raise(RightAws::AwsError.new)
        $fake_sdb.should_not_receive(:put_attributes).with("new_fake_resource_5", "123", anything(), anything(), anything())
        @fake_resource.save! rescue RightAws::AwsError
      end
    end
  end
end
