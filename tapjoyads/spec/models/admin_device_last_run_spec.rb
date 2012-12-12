require 'spec_helper'

describe AdminDeviceLastRun do
  before(:each) do
    # fixtures
    run_time = Time.zone.parse('2000-01-01 00:00:00')
    %w{d1 d2 d3}.each do |udid|
      %w{a1 a2 a3}.each do |app_id|
        last_run        = AdminDeviceLastRun.new
        last_run.udid   = udid
        last_run.app_id = app_id
        last_run.time   = run_time
        last_run.save

        run_time = run_time.advance(:hours => 1)
      end
    end
  end

  describe '.for' do
    it 'returns an empty array if no records are found' do
      AdminDeviceLastRun.for(:udid => 'bad').should be_empty
    end

    it 'fetches the last run time for the given options' do
      AdminDeviceLastRun.for(
        :udid => 'd1',
        :app_id => 'a1'
      ).first.time.should == Time.zone.parse('2000-01-01 00:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd1'
      ).first.time.should == Time.zone.parse('2000-01-01 02:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd2',
        :app_id => 'a2'
      ).first.time.should == Time.zone.parse('2000-01-01 04:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd2'
      ).first.time.should == Time.zone.parse('2000-01-01 05:00:00')

      AdminDeviceLastRun.for(
        :app_id => 'a2'
      ).first.time.should == Time.zone.parse('2000-01-01 07:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd3'
      ).first.time.should == Time.zone.parse('2000-01-01 08:00:00')
    end

    it 'requires at least one of [:udid, :app_id] be provided' do
      expect {
        AdminDeviceLastRun.for({})
      }.to raise_exception(ArgumentError)
    end
  end

  describe '.add' do
    let(:web_request) {
      w = WebRequest.new
      w.user_agent = 'rspec'
      w
    }

    it 'adds a run time for a [:udid, :app_id] tuple' do
      tuple = {:udid => 'd4', :app_id => 'a1'}
      AdminDeviceLastRun.add(tuple.merge(:web_request => web_request))
      AdminDeviceLastRun.for(tuple).first.time.should be_within(2.seconds).of(Time.zone.now)
    end

    it 'does not overwrite existing run times' do
      tuple = {:udid => 'd2', :app_id => 'a3'}
      AdminDeviceLastRun.for(tuple).first.time.
        should_not be_within(2.seconds).of(Time.zone.now)

      AdminDeviceLastRun.add(tuple.merge(:web_request => web_request))

      both_runs = AdminDeviceLastRun.for(tuple)
      both_runs.size.should == 2

      both_runs.last.time.
        should be_within(2.seconds).of(Time.zone.now)

      both_runs.first.time.
        should_not be_within(2.seconds).of(Time.zone.now)

      both_runs.last.time.
        should be_within(2.seconds).of(Time.zone.now)
    end

    it 'requires :udid and :app_id and a :web_request' do
      expect {
        AdminDeviceLastRun.add({})
      }.to raise_exception(ArgumentError)

      expect {
        AdminDeviceLastRun.add({:udid => 'd1'})
      }.to raise_exception(ArgumentError)

      expect {
        AdminDeviceLastRun.add({:udid => 'd1', :app_id => 'd2'})
      }.to raise_exception(ArgumentError)
    end

    it 'returns records from newest -> oldest' do
      tuple = {:udid => 'd5', :app_id => 'a1'}

      w = WebRequest.new
      w.user_agent = 'rspec'
      AdminDeviceLastRun.add(tuple.merge(:web_request => w))

      w = WebRequest.new
      w.user_agent = 'still rspec'
      AdminDeviceLastRun.add(tuple.merge(:web_request => w))

      runs = AdminDeviceLastRun.for(tuple)

      runs.first.user_agent.should == 'still rspec'
      runs.last.user_agent.should == 'rspec'
    end
  end
end
