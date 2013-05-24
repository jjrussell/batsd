require 'spec_helper'

describe RiskProfile do
  subject { RiskProfile.new(:key => 'DEVICE.1234567890') }

  before :each do
    RiskProfile.any_instance.stub(:save)
  end

  describe '#add_curated_offset' do
    it 'adds curated offset' do
      subject.add_curated_offset('test1', 20)
      subject.curated_offsets['test1']['offset'].should == 20
    end
  end

  describe '#add_historical_offset' do
    it 'adds historical offset' do
      subject.add_historical_offset('test2', -40)
      subject.historical_offsets['test2']['offset'].should == -40
    end
  end

  describe '#total_score_offset' do
    it 'returns total offset' do
      subject.add_curated_offset('test1', 20)
      subject.add_historical_offset('test2', -40)
      subject.total_score_offset.should == -10
    end

    context 'when profile includes no historical offsets' do
      it 'adds default offset for profile with no history' do
        subject.add_curated_offset('test1', 20)
        subject.total_score_offset.should == (20 + RiskProfile::NO_HISTORY_OFFSET['no_history']['offset']) / 2
      end
    end

    context 'when adding an offset with a value less than the minimum offset' do
      it 'sets sets value of historical offset to minimum offset value' do
        subject.add_curated_offset('test1', -100)
        subject.add_historical_offset('test2', -101)
        subject.add_historical_offset('test3', -150)
        subject.total_score_offset.should == -100
      end

      it 'sets sets value of curated offset to minimum offset value' do
        subject.add_curated_offset('test1', -100)
        subject.add_historical_offset('test2', -101)
        subject.add_curated_offset('test3', -150)
        subject.total_score_offset.should == -100
      end
    end

    context 'when adding an offset with a value greater than the maximum offset' do
      it 'sets sets value of historical offset to maximum offset value' do
        subject.add_curated_offset('test1', 100)
        subject.add_historical_offset('test2', 103)
        subject.add_historical_offset('test3', 150)
        subject.total_score_offset.should == 100
      end

      it 'sets sets value of curated offset to maximum offset value' do
        subject.add_curated_offset('test1', 100)
        subject.add_historical_offset('test2', 103)
        subject.add_curated_offset('test3', 150)
        subject.total_score_offset.should == 100
      end
    end
  end

  describe '#process_conversion' do
    before :each do
      @now = Time.now
      Timecop.freeze(@now)
      reward = double("reward")
      reward.stub(:advertiser_amount).and_return(-500)
      subject.process_conversion(reward)
    end

    it 'processes a conversion' do
      subject.conversion_tracker.should == {(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s => 1}
      subject.revenue_tracker.should == {(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s => 500}
    end

    context 'when profile has data for current hour' do
      it 'updates existing data' do
        reward = double("reward")
        reward.stub(:advertiser_amount).and_return(-250)
        subject.process_conversion(reward)
        subject.conversion_tracker.should == {(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s => 2}
        subject.revenue_tracker.should == {(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s => 750}
      end
    end

    context 'when profile has no data for current hour' do
      it 'adds data for new hour' do
        original_time = @now
        new_time = @now + 3.hours
        Timecop.freeze(new_time)
        reward = double("reward")
        reward.stub(:advertiser_amount).and_return(-250)
        subject.process_conversion(reward)
        subject.conversion_tracker[(original_time.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should == 1
        subject.conversion_tracker[(new_time.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should == 1
        subject.revenue_tracker[(original_time.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should == 500
        subject.revenue_tracker[(new_time.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should == 250
      end
    end

    it 'clears data older than maximum velocity window' do
      Timecop.freeze(@now + 100.hours)
      subject.revenue_tracker[(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should == 500

      reward = double("reward")
      reward.stub(:advertiser_amount).and_return(-250)
      subject.process_conversion(reward)
      subject.conversion_tracker[(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should be_nil
      subject.revenue_tracker[(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should be_nil
    end

    after :each do
      Timecop.return
    end
  end

  describe '#process_block' do
    before :each do
      @now = Time.now
      Timecop.freeze(@now)
      subject.process_block
    end

    it 'processes a blocked conversion' do
      subject.block_tracker.should == {(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s => 1}
    end

    it 'clears data older than maximum velocity window' do
      Timecop.freeze(@now + 100.hours)
      subject.block_tracker[(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should == 1

      subject.process_block
      subject.block_tracker[(@now.to_i / RiskProfile::SECONDS_PER_HOUR).to_s].should be_nil
    end

    after :each do
      Timecop.return
    end
  end

  context 'with multiple conversions spaced 12 hours apart' do
    before :each do
      @start_time = Time.now
      Timecop.freeze(@start_time)
      reward = double("reward")
      reward.stub(:advertiser_amount).and_return(-500)
      subject.process_conversion(reward)
      subject.process_block
      subject.process_block
      Timecop.freeze(@start_time + 12.hours)
      reward.stub(:advertiser_amount).and_return(-250)
      subject.process_conversion(reward)
    end

    describe '#conversion_count' do
      it 'returns the conversion count of larger window' do
        subject.conversion_count(24).should == 2
      end

      it 'returns the conversion count of smaller window' do
        subject.conversion_count(8).should == 1
      end

      context 'when tracked conversions are outside the given time window' do
        it 'returns 0' do
          Timecop.freeze(@start_time + 40.hours)
          subject.conversion_count(24).should == 0
        end
      end
    end

    describe '#block_count' do
      it 'returns the blocked conversion count' do
        subject.block_count(24).should == 2
      end

      context 'when tracked blocked conversions are outside the given time window' do
        it 'returns 0' do
          Timecop.freeze(@start_time + 40.hours)
          subject.block_count(24).should == 0
        end
      end
    end

    describe '#block_percent' do
      it 'returns the percentage of blocked conversions of larger window' do
        subject.block_percent(24).should == 50.0
      end

      it 'returns the percentage of blocked conversions of smaller window' do
        subject.block_percent(8).should == 0.0
      end

      context 'when tracked conversions are outside the given time window' do
        it 'returns 0' do
          Timecop.freeze(@start_time + 40.hours)
          subject.block_percent(24).should == 0.0
        end
      end
    end

    describe '#revenue_total' do
      it 'returns the total revenue of larger window' do
        subject.revenue_total(24).should == 750
      end

      it 'returns the total revenue of smaller window' do
        subject.revenue_total(8).should == 250
      end

      context 'when tracked conversions are outside the given time window' do
        it 'returns 0' do
          Timecop.freeze(@start_time + 40.hours)
          subject.revenue_total(24).should == 0
        end
      end
    end

    after :each do
      Timecop.return
    end
  end
end
