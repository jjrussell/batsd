require 'spec_helper'

describe ExperimentBucket do
  describe '.rehash_population' do
    it 'creates 50/50 optimization/interface buckets' do
      ExperimentBucket.rehash_population(:buckets => 20)
      ExperimentBucket.count.should == 20
      ExperimentBucket.where(:bucket_type => 'optimization').count.should == 10
      ExperimentBucket.where(:bucket_type => 'interface').count.should == 10
    end

    it 'creates only one type of bucket if :alternate => false' do
      ExperimentBucket.rehash_population(:buckets => 20, :alternate => false)
      ExperimentBucket.count.should == 20
      ExperimentBucket.where(:bucket_type => 'optimization').count.should == 20
      ExperimentBucket.where(:bucket_type => 'interface').count.should == 0
    end

    # NOTE- while this spec is technically true, if you EB.rehash_population
    # with a significantly different number of devices than you expect to
    # be in the system at Experiment-time, you will get weird numbers because
    # we can't guess the approximate size of a bucket.
    it 'does not requre devices to exist before the rehash' do
      ExperimentBucket.rehash_population(:buckets => 2)
      20.times { Factory(:device) }
      Device.select_all.each do |device|
        ExperimentBucket.all.should include(device.experiment_bucket)
      end
    end
  end

  describe '.for_index' do
    it 'makes buckets available (from cache) in alphabetical ID order by integer index' do
      ExperimentBucket.rehash_population(:buckets => 10)
      buckets = ExperimentBucket.order('id asc').all

      [:where, :find, :all].each { |m| ExperimentBucket.should_not_receive(m) }
      buckets.each_with_index do |bucket, i|
        ExperimentBucket.for_index(i).should == bucket
      end
    end
  end
end
