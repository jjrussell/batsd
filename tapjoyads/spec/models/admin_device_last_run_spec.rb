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
    it 'returns nil if a record cannot be found' do
      AdminDeviceLastRun.for(:udid => 'bad').should == nil
    end

    it 'fetches the last run time for the given options' do
      AdminDeviceLastRun.for(
        :udid => 'd1',
        :app_id => 'a1'
      ).time.should == Time.zone.parse('2000-01-01 00:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd1'
      ).time.should == Time.zone.parse('2000-01-01 02:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd2',
        :app_id => 'a2'
      ).time.should == Time.zone.parse('2000-01-01 04:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd2'
      ).time.should == Time.zone.parse('2000-01-01 05:00:00')

      AdminDeviceLastRun.for(
        :app_id => 'a2'
      ).time.should == Time.zone.parse('2000-01-01 07:00:00')

      AdminDeviceLastRun.for(
        :udid => 'd3'
      ).time.should == Time.zone.parse('2000-01-01 08:00:00')
    end

    it 'requires at least one of [:udid, :app_id] be provided' do
      expect {
        AdminDeviceLastRun.for({})
      }.to raise_exception(ArgumentError)
    end
  end

  describe '.set' do
    let(:web_request) {
      w = WebRequest.new
      w.user_agent = 'rspec'
      w
    }

    it 'sets the last run time for a new [:udid, :app_id] tuple' do
      tuple = {:udid => 'd4', :app_id => 'a1'}
      AdminDeviceLastRun.set(tuple.merge(:web_request => web_request))
      AdminDeviceLastRun.for(tuple).time.should be_within(2.seconds).of(Time.zone.now)
    end

    it 'updates the last run time of an existing [:udid, :app_id] tuple' do
      tuple = {:udid => 'd2', :app_id => 'a3'}
      AdminDeviceLastRun.for(tuple).time.
        should_not be_within(2.seconds).of(Time.zone.now)

      AdminDeviceLastRun.set(tuple.merge(:web_request => web_request))

      AdminDeviceLastRun.for(tuple).time.
        should be_within(2.seconds).of(Time.zone.now)
    end

    it 'requires :udid and :app_id and a :web_request' do
      expect {
        AdminDeviceLastRun.set({})
      }.to raise_exception(ArgumentError)

      expect {
        AdminDeviceLastRun.set({:udid => 'd1'})
      }.to raise_exception(ArgumentError)

      expect {
        AdminDeviceLastRun.set({:udid => 'd1', :app_id => 'd2'})
      }.to raise_exception(ArgumentError)
    end

    it 'stores associated data from a WebRequest' do
      tuple = {:udid => 'd5', :app_id => 'a1'}

      w = WebRequest.new
      w.user_agent = 'rspec'
      AdminDeviceLastRun.set(tuple.merge(:web_request => w))
      first_last_run = AdminDeviceLastRun.for(tuple)

      w = WebRequest.new
      w.user_agent = 'still rspec'
      AdminDeviceLastRun.set(tuple.merge(:web_request => w))
      last_last_run = AdminDeviceLastRun.for(tuple)

      first_last_run.key.should == last_last_run.key
      first_last_run.user_agent.should_not == last_last_run.user_agent
    end
  end
end