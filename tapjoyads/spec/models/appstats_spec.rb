require 'spec_helper'

describe Appstats do
  describe '#get_times' do
    before :each do
      @now = Time.zone.now.beginning_of_hour
      @default_dates = [@now - 23.hours, @now + 1.hour]
      Timecop.freeze(@now)
    end
    after { Timecop.return }

    context 'with nothing passed in' do
      it 'returns last 24 hours' do
        @default_dates = [@now - 23.hours, @now + 1.hour]
        Appstats.send(:get_times, nil, nil).should == @default_dates
      end
    end

    context 'with valid strings' do
      it 'returns valid times' do
        start_time = Date.parse('2012-03-20')
        @default_dates = [start_time, start_time + 24.hours]
        Appstats.send(:get_times, start_time.to_s, nil).should == @default_dates
      end
    end

    context 'invalid inputs' do
      context 'invalid start time' do
        it 'returns default times' do
          Appstats.send(:get_times, '2012-00-a', nil).should == @default_dates
        end
      end

      context 'invalid finish time' do
        it 'returns default times' do
          Appstats.send(:get_times, nil, '2012-00-a').should == @default_dates
        end
      end
    end
  end
end
