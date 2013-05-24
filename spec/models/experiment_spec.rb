require 'spec_helper'

describe Experiment do
  describe 'associations' do
    before(:each) do
      # Get two of each bucket type
      50.times { Factory(:device) }
      ExperimentBucket.rehash_population(:buckets => 4)

      # Some experiments and apps to test with
      2.times { Factory(:experiment).save }
      3.times { Factory(:app).save }
    end

    describe '#apps' do
      it 'refuses to add an app that belongs to another experiment' do
        e1, e2 = Experiment.first(2)
        apps = App.first(3)

        e1.apps << apps.first
        e1.apps << apps.second
        e1.save

        e2.apps.should be_empty

        # apps.first already belongs to e1
        expect { e2.apps << apps.first }.to raise_exception(Experiment::AppNotAvailable)
        expect { e2.apps << apps.last }.to_not raise_exception

        # Apps belong to correct experiment
        apps.each(&:reload)
        [apps.first, apps.second].each { |app| app.experiment.should == e1 }

        # Verify association is correct in the other direction as well
        e1.apps.should include(apps.first, apps.second)
        e2.apps.should include(apps.last)
      end
    end

    describe '#buckets' do
      it 'refuses to add a bucket that belongs to another experiment' do
        e1, e2 = Experiment.first(2)
        b1, b2 = ExperimentBucket.first(2)

        e1.buckets << b1
        e1.buckets << b2
        e1.save

        expect { e2.buckets << b2 }.to raise_exception(Experiment::BucketNotAvailable)

        [b1, b2].each { |bucket| bucket.experiment.should == e1 }
        e1.buckets.should               == [b1, b2]
        e1.metadata[:bucket_ids].should == [b1.id, b2.id]
      end
    end

    describe '#app_ids' do
      it 'returns a comma separated list of App ids in this experiment' do
        e = Experiment.first
        apps = App.first(2)

        e.apps << apps.first
        e.apps << apps.last

        e.app_ids.should == [apps.first.id, apps.last.id].join(',')
      end
    end

    describe '#app_ids=' do
      it 'assigns apps to the experiment from a comma separated list of ids' do
        e = Experiment.first
        apps = App.first(2)

        e.app_ids = [apps.first.id, apps.last.id].join(',')
        e.apps.should include(*apps)
      end

      it 'refuses to add an app that belongs to another experiment' do
        e1, e2 = Experiment.first(2)
        apps = App.first(3)

        e1.app_ids = [apps.first.id, apps.second.id].join(',')
        e1.save

        # apps.first already belongs to e1
        expect {
          e2.app_ids = e2.app_ids + ',' + apps.first.id
        }.to raise_exception(Experiment::AppNotAvailable)

        expect {
          e2.app_ids = e2.app_ids + ',' + apps.last.id
        }.to_not raise_exception

        # Apps belong to correct experiment
        apps.each(&:reload)
        [apps.first, apps.second].each { |app| app.experiment.should == e1 }
        apps.last.experiment.should == e2

        # Verify association is correct in the other direction as well
        e1.apps.should include(apps.first, apps.second)
        e2.apps.should == [apps.last]
      end
    end
  end

  describe '#reserve_devices!' do
    before(:each) do
      60.times { Factory(:device) }
      ExperimentBucket.rehash_population(:buckets => 6)
    end

    it 'assigns buckets (and therefore devices) to an experiment' do
      Factory(:experiment, :population_size => 20).tap do |e|
        e.reserve_devices!
        e.reserved_devices.should >= 20

        reserved_buckets                 = ExperimentBucket.where(:experiment_id => e.id)
        reserved_buckets.size.should     > 0
        reserved_buckets.size.should_not == ExperimentBucket.count
        reserved_buckets.should          include(*e.buckets)
      end
    end

    it 'bails if there are not enough users available' do
      e1, e2 = 2.times.collect { Factory(:experiment, :population_size => 20) }

      e1.reserve_devices!
      e1.reserved_devices.should >= 20
      e1.save

      expect { e2.reserve_devices! }.to raise_exception(Experiment::NoAvailableBuckets)
    end

    it 'bails if the experiment has already reserved devices' do
      Factory(:experiment, :population_size => 10).tap do |e|
        e.reserve_devices!
        expect { e.reserve_devices! }.to raise_exception(Experiment::AlreadyHasBuckets)
      end
    end

    it 'reserves buckets of the proper type' do
      Factory(:experiment, :bucket_type => 'interface', :population_size => 20).tap do |e|
        e.reserve_devices!
        e.buckets.each { |bucket| bucket.bucket_type.should == 'interface' }
      end

      # Not enough users left in interface buckets
      expect {
        Factory(:experiment, :bucket_type => 'interface', :population_size => 20)
      }.to raise_exception(ActiveRecord::RecordInvalid)

      # But we do have some optimization buckets available
      Factory(:experiment, :bucket_type => 'optimization', :population_size => 20).tap do |e|
        e.reserve_devices!
        e.buckets.each { |bucket| bucket.bucket_type.should == 'optimization' }
      end
    end
  end

  describe '#group_for' do
    context 'for devices excluded from the experiment' do
      it 'returns nil' do
        d = Factory(:device)
        e = Experiment.new

        e.group_for(d).should == nil
      end
    end

    context 'for devices included in the experiment' do
      context 'when the experiment is not running' do
        it 'returns "control" for all devices' do
          40.times { Factory(:device) }
          ExperimentBucket.rehash_population(:buckets => 4, :alternate => false)

          Factory(:experiment, :population_size => 40, :started_at => Date.tomorrow).tap do |e|
            e.reserve_devices!

            e.running?.should   be_false
            e.scheduled?.should be_true
            e.concluded?.should be_false

            e.buckets.each do |bucket|
              Device.select_all.each { |d| e.group_for(d) == 'control' }.should be_true
            end

            excluded_device = double('device')
            excluded_device.stub(:experiment_bucket_id) { 'fake' }
            e.group_for(excluded_device).should == nil # sanity
          end
        end
      end

      context 'when the experiment is running' do
        it 'returns "test" for the appropriate percentage of devices' do
          1000.times { Factory(:device) }
          ExperimentBucket.rehash_population(:buckets => 4, :alternate => false)

          Factory(:experiment,
            :population_size => 1000,
            :ratio           => 15
          ).tap do |e|
            e.reserve_devices!
            e.start!
            e.running?.should   be_true
            e.scheduled?.should be_false
            e.concluded?.should be_false

            {'control' => 0, 'test' => 0}.tap do |group_counts|
              Device.select_all.each { |d| group_counts[e.group_for(d)] += 1 }
              ratio = group_counts['test'] / group_counts.values.reduce(:+).to_f
              (ratio * 100).should be_within(5).of(e.ratio)
            end
          end
        end

        it 'always places a device in the same group (per experiment)' do
          99.times { Factory(:device) }
          device   = Factory(:device)
          ExperimentBucket.rehash_population(:buckets => 1, :alternate => false)

          Factory(:experiment,
            :population_size => 100,
            :ratio           => 40
          ).tap do |e|
            e.reserve_devices!
            e.start!

            runs = 20.times.collect {
              e.group_for(device)
            }

            runs.each_cons(2) { |a, b| a.should == b }
          end
        end
      end
    end
  end

  describe '#start!' do
    it 'starts the experiment immediately' do
      Factory(:device)
      ExperimentBucket.rehash_population(:buckets => 1)

      Factory(:experiment,
        :started_at      => Date.today.advance(:days => 3),
        :due_at          => Date.today.advance(:days => 5),
        :population_size => 1
      ).tap do |e|
        e.reserve_devices!
        e.scheduled?.should be_true
        e.start!
        e.running?.should be_true
        e.started_at.should < Time.now
      end
    end
  end

  describe '#conclude!' do
    before(:each) {
      10.times { Factory(:device) }
      ExperimentBucket.rehash_population(:buckets => 5, :alternate => false)
    }

    it 'can end the experiment early' do
      Factory(:experiment,
        :population_size => 4
      ).tap do |e|
        e.reserve_devices!
        e.buckets.size.should satisfy { |n| n > 0 && n < 5 }
        bucket_ids = e.buckets.collect &:id

        e.start!
        e.running?.should be_true
        e.conclude!
        e.running?.should be_false
        e.concluded?.should be_true
        e.buckets.size.should == 0
        e.metadata[:bucket_ids].sort.should == bucket_ids.sort
      end
    end

    it 'frees associations but does not destroy metadata' do
      Factory(:experiment,
        :population_size => 4
      ).tap do |e|
        e.reserve_devices!
        buckets = e.buckets

        e.start!
        e.conclude!

        buckets.all? { |b| b.reload.experiment_id.nil? }.should be_true
        e.metadata[:bucket_ids].should == buckets.collect(&:id)
      end
    end
  end

  describe '.[]' do
    it 'looks up experiments by name from cache' do
      20.times { Factory(:device) } # TODO this test will fail with probability 0.5**20
      ExperimentBucket.rehash_population(:buckets => 2, :alternate => false)

      e1 = Factory(:experiment, :name => 'one')
      e2 = Factory(:experiment, :name => 'two')

      [:where, :find].each { |m| Experiment.should_not_receive(m) }

      Experiment['one'].should == e1
      Experiment['two'].should == e2

      # Symbols are fine
      Experiment[:one].should  == e1
    end

    it 'raises an exception when the experiment is not cached by name' do
      expect {
        Experiment['nope']
      }.to raise_exception(ActiveRecord::RecordNotFound,
        "No experiment found in cache by name 'nope'"
      )
    end
  end
end
