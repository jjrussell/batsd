require 'spec/spec_helper'

describe Job::QueueSendCurrencyController do
  describe 'the send currency queue' do
    before :each do
      @controller.expects(:authenticate).at_least_once.returns(true)
      Resolv.expects(:getaddress).at_least_once.returns(true)
      @currency = Factory(:currency, :callback_url => 'http://www.whatwhat.com')
      @reward = Factory(:reward, :currency_id => @currency.id)
    end

    describe 'when dealing with errors' do
      before :each do
        class TestingError < RuntimeError; end
        Downloader.expects(:get_strict).at_least_once.raises(TestingError)
        Time.zone.stubs(:now).returns(Time.zone.parse('2011-02-15'))
        @mc_time = Time.zone.now.to_i / 1.hour
        Mc.delete("send_currency_failures.#{@mc_time}")
      end

      it 'should record an error for Downloader' do
        lambda {
          get 'run_job', :message => @reward.serialize
        }.should raise_error(TestingError)

        failures = Mc.get("send_currency_failures.#{@mc_time}")
        failures[@currency.id].should == Set.new(@reward.key)
      end

      it 'should throw SkippedSendCurrency if callback is bad' do
        get 'run_job', :message => @reward.serialize rescue TestingError

        lambda {
          get 'run_job', :message => @reward.serialize
        }.should raise_error(SkippedSendCurrency)
      end

      it 'should record errors for multiple currencies' do
        get 'run_job', :message => @reward.serialize rescue TestingError

        currency = Factory(:currency, :callback_url => 'https://www.whatnot.com')
        reward = Factory(:reward, :currency_id => currency.id)

        lambda {
          get 'run_job', :message => reward.serialize
        }.should raise_error(TestingError)

        failures = Mc.get("send_currency_failures.#{@mc_time}")

        failures[@currency.id].should == Set.new(@reward.key)
        failures[currency.id].should == Set.new(reward.key)
      end
    end
  end
end
