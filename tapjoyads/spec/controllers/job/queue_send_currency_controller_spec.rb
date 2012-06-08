require 'spec/spec_helper'

describe Job::QueueSendCurrencyController do
  before :each do
    SimpledbResource.reset_connection
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    @mock_response = mock()
    @mock_response.stub(:status).and_return('OK')

    # prevents any callback_urls from actually getting called
    Downloader.stub(:get).and_return(@mock_response)
    Resolv.should_receive(:getaddress).at_least(:once).and_return(true)

    @currency = Factory(:currency, :callback_url => 'http://www.whatwhat.com')

    @reward = FactoryGirl.build(
      :reward,
      :currency_id => @currency.id,
      :publisher_app_id => @currency.id,
      :created => Time.zone.parse('2011-02-15')
    )
    @reward.save
  end

  after :each do
    Timecop.return
  end

  describe 'with ExpectedAttributeError' do
    it 'should raise if reward has not already been updated' do
      Reward.
        any_instance.should_receive(:save!).
        with(
          :expected_attr => {'sent_currency' => nil}
        ).
        and_raise(Simpledb::ExpectedAttributeError)

      $redis.should_receive(:sadd).with('queue:send_currency:failures', @reward.id)
      get(:run_job, :message => @reward.id)
    end

    it 'should return if reward is already updated' do
      @reward.send_currency_status = 'poo'
      @reward.save

      Reward.
        any_instance.
        should_receive(:save).
        and_raise(Simpledb::ExpectedAttributeError)

      get(:run_job, :message => @reward.id)
    end
  end

  describe 'with Downloader errors' do
    before :each do
      class TestingError < RuntimeError; end
      Downloader.should_receive(:get_strict).at_least(:once).and_raise(TestingError)

      @mc_time = Time.zone.now.to_i / 1.hour
      @fail_count_key = "send_currency_failure.#{@currency.id}.#{@mc_time}"
      Mc.delete("send_currency_failures.#{@mc_time}")
    end

    it 'should record an error for Downloader' do
      expect {
        get(:run_job, :message => @reward.id)
      }.to raise_error(TestingError)

      failures = Mc.get("send_currency_failures.#{@mc_time}")
      failures[@currency.id].should == Set.new(@reward.key)
    end

    it 'should throw SkippedSendCurrency if callback is bad' do
      get(:run_job, :message => @reward.id) rescue TestingError

      Mc.get_count("send_currency_skip.#{@currency.id}.#{@mc_time}").should == 0

      message = "not attempting to ping the callback for #{@currency.id}"
      expect {
        get(:run_job, :message => @reward.id)
      }.to raise_error(SkippedSendCurrency, message)

      Mc.get_count("send_currency_skip.#{@currency.id}.#{@mc_time}").should == 1
    end

    it 'should record errors for multiple currencies' do
      get(:run_job, :message => @reward.id) rescue TestingError

      currency = Factory(:currency, :callback_url => 'https://www.whatnot.com')
      reward = Factory(:reward, :currency_id => currency.id)

      expect {
        get(:run_job, :message => reward.id)
      }.to raise_error(TestingError)

      failures = Mc.get("send_currency_failures.#{@mc_time}")

      failures[@currency.id].should == Set.new(@reward.key)
      failures[currency.id].should == Set.new(reward.key)
    end

    it 'should not record more than 5000 errors' do
      Mc.increment_count(@fail_count_key, false, 1.week, 4998)

      get(:run_job, :message => @reward.id) rescue TestingError

      reward = Factory(:reward, :currency_id => @currency.id)
      @controller.instance_variable_set('@bad_callbacks', Set.new)

      get(:run_job, :message => reward.id) rescue TestingError

      failures = Mc.get("send_currency_failures.#{@mc_time}")
      failures[@currency.id].should == Set.new(@reward.key)
    end

    it 'should count errors in memcache' do
      count = Mc.get_count(@fail_count_key)
      count.should == 0

      get(:run_job, :message => @reward.id) rescue TestingError

      count = Mc.get_count(@fail_count_key)
      count.should == 1
    end

    it 'should delete sent_currency from reward' do
      expect {
        get(:run_job, :message => @reward.id)
      }.to raise_error(TestingError)

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.should == nil
    end

    it 'should increase @num_reads on error' do
      expect {
        get(:run_job, :message => @reward.id)
      }.to raise_error(TestingError)

      num_reads = @controller.instance_variable_get('@num_reads')
      num_reads.should == 100

      get(:run_job, :message => @reward.id) rescue TestingError

      num_reads = @controller.instance_variable_get('@num_reads')
      num_reads.should == 101

      @controller.instance_variable_set('@num_reads', 200)

      get(:run_job, :message => @reward.id) rescue TestingError

      num_reads = @controller.instance_variable_get('@num_reads')
      num_reads.should == 200
    end
  end

  describe 'without errors' do
    before :each do
      Downloader.should_receive(:get_strict).and_return(@mock_response)
    end

    it 'should save the reward' do
      Currency.
        should_receive(:find_in_cache).
        with(@currency.id, true).
        and_return(@currency)

      get(:run_job, :message => @reward.id)

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.to_i.should be_within(1).of(Time.zone.now.to_i)
      reward.send_currency_status.should == 'OK'
    end

    it 'should not reward twice' do
      get(:run_job, :message => @reward.id)

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.to_i.should be_within(1).of(Time.zone.now.to_i)

      Currency.should_receive(:find_in_cache).never
      get(:run_job, :message => reward.id)
    end
  end

  describe 'with TJ managed currency' do
    before :each do
      @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
      @currency.save!
    end

    it 'should add up point purchases' do
      pp_key = "#{@reward.publisher_user_id}.#{@reward.publisher_app_id}"
      pp = PointPurchases.new(:key => pp_key)

      pp.points.should == 0

      get(:run_job, :message => @reward.id)

      pp = PointPurchases.new(:key => pp_key, :consistent => true)
      pp.points.should == 100
    end

    it 'should set send_currency_status to OK' do
      get(:run_job, :message => @reward.id)

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.send_currency_status.should == 'OK'
    end
  end

  describe 'with callback url' do
    it 'should have verifier if currency has a secret key' do
      @currency.update_attribute(:secret_key, 'top secret')

      verifier_params = [
        @reward.key,
        @reward.publisher_user_id,
        @reward.currency_reward,
        @currency.secret_key,
      ]
      verifier = Digest::MD5.hexdigest(verifier_params.join(':'))

      url_params = [
        "snuid=#{@reward.publisher_user_id}",
        "currency=#{@reward.currency_reward}",
        "mac_address=",
        "id=#{@reward.key}",
        "verifier=#{verifier}",
      ]
      callback_url = "#{@currency.callback_url}?#{url_params.join('&')}"

      Downloader.
        should_receive(:get_strict).
        with(callback_url, { :timeout => 20 }).
        and_return(@mock_response)

      get(:run_job, :message => @reward.id)
    end

    it 'should send offer data if currency says so' do
      app = Factory(:app)
      offer = app.primary_offer

      @currency.update_attribute(:id, app.id)
      @currency.update_attribute(:send_offer_data, true)

      Currency.should_receive(:find_in_cache).and_return(@currency)

      @reward.currency_id = @currency.id
      @reward.offer_id = offer.id
      @reward.publisher_amount = 150
      @reward.save

      url_params = [
        "snuid=#{@reward.publisher_user_id}",
        "currency=#{@reward.currency_reward}",
        "mac_address=",
        "storeId=#{CGI::escape(offer.store_id_for_feed)}",
        "application=#{CGI::escape(offer.name)}",
        "rev=1.5",
      ]
      callback_url = "#{@currency.callback_url}?#{url_params.join('&')}"

      Downloader.
        should_receive(:get_strict).
        with(callback_url, { :timeout => 20 }).
        and_return(@mock_response)

      Offer.
        should_receive(:find_in_cache).
        with(offer.id, true).
        and_return(offer)

      get(:run_job, :message => @reward.id)
    end

    it 'should adjust the mark if the callback_url has a ?' do
      @currency.callback_url << '?'
      @currency.save!

      Currency.should_receive(:find_in_cache).and_return(@currency)

      url_params = [
        "snuid=#{@reward.publisher_user_id}",
        "currency=#{@reward.currency_reward}",
        "mac_address=",
      ]
      callback_url = "#{@currency.callback_url}&#{url_params.join('&')}"

      Downloader.
        should_receive(:get_strict).
        with(callback_url, { :timeout => 20 }).
        and_return(@mock_response)

      get(:run_job, :message => @reward.id)
    end
  end

  describe 'with callback url for Playdom' do
    before :each do
      @currency.update_attribute(:callback_url, Currency::PLAYDOM_CALLBACK_URL)

      @url_start = "http://offer-dynamic-lb.playdom.com/tapjoy/mob/"
      @url_end = "/fp/main?snuid=bill&currency=#{@reward.currency_reward}&mac_address="
    end

    it 'should set callback for facebook' do
      @reward.publisher_user_id = 'Fbill'
      @reward.save

      callback_url = "#{@url_start}facebook#{@url_end}"

      Downloader.
        should_receive(:get_strict).
        with(callback_url, { :timeout => 20 }).
        and_return(@mock_response)

      get(:run_job, :message => @reward.id)
    end

    it 'should set callback for myspace' do
      @reward.publisher_user_id = 'Mbill'
      @reward.save

      callback_url = "#{@url_start}myspace#{@url_end}"

      Downloader.
        should_receive(:get_strict).
        with(callback_url, { :timeout => 20 }).
        and_return(@mock_response)

      get(:run_job, :message => @reward.id)
    end

    it 'should set callback for iphone' do
      @reward.publisher_user_id = 'Pbill'
      @reward.save

      callback_url = "#{@url_start}myspace#{@url_end}"

      Downloader.
        should_receive(:get_strict).
        with(callback_url, { :timeout => 20 }).
        and_return(@mock_response)

      get(:run_job, :message => @reward.id)
    end

    it 'should set InvalidPlaydomUserId' do
      @reward.publisher_user_id = 'Gbill'
      @reward.save

      get(:run_job, :message => @reward.id)

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.send_currency_status.should == 'InvalidPlaydomUserId'
    end
  end
end
