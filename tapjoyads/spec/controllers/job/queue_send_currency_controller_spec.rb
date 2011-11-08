require 'spec/spec_helper'

describe Job::QueueSendCurrencyController do
  before :each do
    @controller.expects(:authenticate).at_least_once.returns(true)
    @mock_response = mock()
    @mock_response.stubs(:status).returns('OK')

    # prevents any callback_urls from actually getting called
    Downloader.stubs(:get).returns(@mock_response)
    Resolv.expects(:getaddress).at_least_once.returns(true)
    Time.zone.stubs(:now).returns(Time.zone.parse('2011-02-15'))

    @currency = Factory(:currency, :callback_url => 'http://www.whatwhat.com')

    @reward = FactoryGirl.build(
      :reward,
      :currency_id => @currency.id,
      :publisher_app_id => @currency.id
    )
  end

  describe 'with ExpectedAttributeError' do
    it 'should raise if reward has not already been updated' do
      Reward.
        any_instance.expects(:serial_save).
        with(
          :catch_exceptions => false,
          :expected_attr => {'sent_currency' => nil}
        ).
        raises(Simpledb::ExpectedAttributeError)

      lambda {
        get 'run_job', :message => @reward.serialize
      }.should raise_error(Simpledb::ExpectedAttributeError)
    end

    it 'should return if reward is already updated' do
      @reward.send_currency_status = 'poo'
      @reward.serial_save

      Reward.
        any_instance.
        expects(:serial_save).
        raises(Simpledb::ExpectedAttributeError)

      lambda {
        get 'run_job', :message => @reward.serialize
      }.should_not raise_error
    end
  end

  describe 'with Downloader errors' do
    before :each do
      class TestingError < RuntimeError; end
      Downloader.expects(:get_strict).at_least_once.raises(TestingError)

      @mc_time = Time.zone.now.to_i / 1.hour
      @fail_count_key = "send_currency_failure.#{@currency.id}.#{@mc_time}"
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

      Mc.get_count("send_currency_skip.#{@currency.id}.#{@mc_time}").should == 0

      message = "not attempting to ping the callback for #{@currency.id}"
      lambda {
        get 'run_job', :message => @reward.serialize
      }.should raise_error(SkippedSendCurrency, message)

      Mc.get_count("send_currency_skip.#{@currency.id}.#{@mc_time}").should == 1
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

    it 'should not record more than 5000 errors' do
      Mc.increment_count(@fail_count_key, false, 1.week, 4998)

      get 'run_job', :message => @reward.serialize rescue TestingError

      reward = Factory(:reward, :currency_id => @currency.id)
      @controller.instance_variable_set('@bad_callbacks', Set.new)

      get 'run_job', :message => reward.serialize rescue TestingError

      failures = Mc.get("send_currency_failures.#{@mc_time}")
      failures[@currency.id].should == Set.new(@reward.key)
    end

    it 'should count errors in memcache' do
      count = Mc.get_count(@fail_count_key)
      count.should == 0

      get 'run_job', :message => @reward.serialize rescue TestingError

      count = Mc.get_count(@fail_count_key)
      count.should == 1
    end

    it 'should delete sent_currency from reward' do
      get 'run_job', :message => @reward.serialize rescue TestingError

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.should == nil
    end

    it 'should increase @num_reads on error' do
      get 'run_job', :message => @reward.serialize rescue TestingError

      num_reads = @controller.instance_variable_get('@num_reads')
      num_reads.should == 100

      get 'run_job', :message => @reward.serialize rescue TestingError

      num_reads = @controller.instance_variable_get('@num_reads')
      num_reads.should == 101

      @controller.instance_variable_set('@num_reads', 200)

      get 'run_job', :message => @reward.serialize rescue TestingError

      num_reads = @controller.instance_variable_get('@num_reads')
      num_reads.should == 200
    end

    it 'should send errors to NewRelic' do
      url_params = [
        "snuid=#{@reward.publisher_user_id}",
        "currency=#{@reward.currency_reward}",
      ]

      callback_url = "#{@currency.callback_url}?#{url_params.join('&')}"
      NewRelic::Agent.agent.error_collector.
        expects(:notice_error).
        with(
          kind_of(TestingError),
          has_entries({
            :request_params => has_entries('callback_url' => callback_url)
          })
        )

      mock_queue = mock()
      mock_queue.stubs(:receive).returns(@reward.serialize, nil)
      mock_queue.stubs(:visibility).returns(1)
      Sqs.expects(:queue).returns(mock_queue)

      get 'index'
    end

    it 'should send errors to NewRelic for TJ managed Currency' do
      Downloader.get_strict rescue TestingError
      PointPurchases.expects(:transaction).raises(TestingError)
      callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
      @currency.update_attribute(:callback_url, callback_url)
      NewRelic::Agent.agent.error_collector.
        expects(:notice_error).
        with(
          kind_of(TestingError),
          has_entries({
            :request_params => has_entries('callback_url' => callback_url)
          })
        )

      mock_queue = mock()
      mock_queue.stubs(:receive).returns(@reward.serialize, nil)
      mock_queue.stubs(:visibility).returns(1)
      Sqs.expects(:queue).returns(mock_queue)

      get 'index'
    end
  end

  describe 'without errors' do
    before :each do
      Downloader.expects(:get_strict).returns(@mock_response)
    end

    it 'should save the reward' do
      Currency.
        expects(:find_in_cache).
        with(@currency.id, true).
        returns(@currency)

      get 'run_job', :message => @reward.serialize

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.should == Time.zone.now
      reward.send_currency_status.should == 'OK'
    end

    it 'should delete the callback url' do
      HashWithIndifferentAccess.
        any_instance.
        expects(:delete).
        with(:callback_url).
        times(2)

      get 'run_job', :message => @reward.serialize
    end

    it 'should not reward twice' do
      get 'run_job', :message => @reward.serialize

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.should == Time.zone.now

      Currency.expects(:find_in_cache).never
      get 'run_job', :message => reward.serialize
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

      get 'run_job', :message => @reward.serialize

      pp = PointPurchases.new(:key => pp_key, :consistent => true)
      pp.points.should == 100
    end

    it 'should set send_currency_status to OK' do
      get 'run_job', :message => @reward.serialize

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
        "id=#{@reward.key}",
        "verifier=#{verifier}",
      ]
      callback_url = "#{@currency.callback_url}?#{url_params.join('&')}"

      Downloader.
        expects(:get_strict).
        with(callback_url, { :timeout => 20 }).
        returns(@mock_response)

      get 'run_job', :message => @reward.serialize
    end

    it 'should send offer data if currency says so' do
      app = Factory(:app)
      offer = app.primary_offer

      @currency.update_attribute(:id, app.id)
      @currency.update_attribute(:send_offer_data, true)

      Currency.expects(:find_in_cache).returns(@currency)

      @reward.currency_id = @currency.id
      @reward.offer_id = offer.id
      @reward.publisher_amount = 150
      @reward.serial_save

      url_params = [
        "snuid=#{@reward.publisher_user_id}",
        "currency=#{@reward.currency_reward}",
        "storeId=#{CGI::escape(offer.store_id_for_feed)}",
        "application=#{CGI::escape(offer.name)}",
        "rev=1.5",
      ]
      callback_url = "#{@currency.callback_url}?#{url_params.join('&')}"

      Downloader.
        expects(:get_strict).
        with(callback_url, { :timeout => 20 }).
        returns(@mock_response)

      Offer.
        expects(:find_in_cache).
        with(offer.id, true).
        returns(offer)

      get 'run_job', :message => @reward.serialize
    end

    it 'should adjust the mark if the callback_url has a ?' do
      @currency.callback_url << '?'
      @currency.save!

      Currency.expects(:find_in_cache).returns(@currency)

      url_params = [
        "snuid=#{@reward.publisher_user_id}",
        "currency=#{@reward.currency_reward}",
      ]
      callback_url = "#{@currency.callback_url}&#{url_params.join('&')}"

      Downloader.
        expects(:get_strict).
        with(callback_url, { :timeout => 20 }).
        returns(@mock_response)

      get 'run_job', :message => @reward.serialize
    end
  end

  describe 'with callback url for Playdom' do
    before :each do
      @currency.update_attribute(:callback_url, Currency::PLAYDOM_CALLBACK_URL)

      @url_start = "http://offer-dynamic-lb.playdom.com/tapjoy/mob/"
      @url_end = "/fp/main?snuid=bill&currency=#{@reward.currency_reward}"
    end

    it 'should set callback for facebook' do
      @reward.publisher_user_id = 'Fbill'

      callback_url = "#{@url_start}facebook#{@url_end}"

      Downloader.
        expects(:get_strict).
        with(callback_url, { :timeout => 20 }).
        returns(@mock_response)

      get 'run_job', :message => @reward.serialize
    end

    it 'should set callback for myspace' do
      @reward.publisher_user_id = 'Mbill'

      callback_url = "#{@url_start}myspace#{@url_end}"

      Downloader.
        expects(:get_strict).
        with(callback_url, { :timeout => 20 }).
        returns(@mock_response)

      get 'run_job', :message => @reward.serialize
    end

    it 'should set callback for iphone' do
      @reward.publisher_user_id = 'Pbill'

      callback_url = "#{@url_start}myspace#{@url_end}"

      Downloader.
        expects(:get_strict).
        with(callback_url, { :timeout => 20 }).
        returns(@mock_response)

      get 'run_job', :message => @reward.serialize
    end

    it 'should set InvalidPlaydomUserId' do
      @reward.publisher_user_id = 'Gbill'

      get 'run_job', :message => @reward.serialize

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.send_currency_status.should == 'InvalidPlaydomUserId'
    end
  end
end
