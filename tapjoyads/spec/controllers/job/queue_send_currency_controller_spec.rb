require 'spec_helper'

describe Job::QueueSendCurrencyController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
    @mock_response = mock()
    @mock_response.stub(:status).and_return(200)
    @mock_response.stub(:body).and_return("mock response body")

    # prevents any callback_urls from actually getting called
    Downloader.stub(:get).and_return(@mock_response)
    Resolv.should_receive(:getaddress).at_least(:once).and_return(true)

    @currency = FactoryGirl.create(:currency, :callback_url => 'http://www.whatwhat.com')
    
    @publisher_app = FactoryGirl.create(:app, :id => @currency.id)
    advertiser_app = FactoryGirl.create(:app)
    @offer = advertiser_app.primary_offer

    @reward = FactoryGirl.build(
      :reward,
      :type                  => 'offer',
      :advertiser_app_id     => advertiser_app.id,
      :offer_id              => @offer.id,
      :currency_id => @currency.id,
      :publisher_app_id => @currency.id,
      :created => Time.zone.parse('2011-02-15')
    )
    Currency.stub(:find_in_cache).with(@reward.currency_id, :do_lookup => true).and_return(Currency.find(@reward.currency_id))
    @reward.save
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
      Downloader.should_receive(:get).at_least(:once).and_raise(TestingError)

      @now = Time.zone.now
      @mc_time = @now.to_i / 1.hour
      @fail_count_key = "send_currency_failure.#{@currency.id}.#{@mc_time}"
      Mc.delete("send_currency_failures.#{@mc_time}")
    end

    it 'should record an error for Downloader' do
      Timecop.freeze(@now) do
        expect {
          get(:run_job, :message => @reward.id)
        }.to raise_error(TestingError)
      end

      failures = Mc.get("send_currency_failures.#{@mc_time}")
      failures[@currency.id].should == Set.new.add(@reward.key)
    end

    it 'should throw SkippedSendCurrency if callback is bad' do
      Timecop.freeze(@now) do
        get(:run_job, :message => @reward.id) rescue TestingError
      end

      Mc.get_count("send_currency_skip.#{@currency.id}.#{@mc_time}").should == 0

      message = "not attempting to ping the callback for #{@currency.id}"
      Timecop.freeze(@now) do
        expect {
          get(:run_job, :message => @reward.id)
        }.to raise_error(SkippedSendCurrency, message)
      end

      Mc.get_count("send_currency_skip.#{@currency.id}.#{@mc_time}").should == 1
    end

    it 'should record errors for multiple currencies' do
       Timecop.freeze(@now) do
         get(:run_job, :message => @reward.id) rescue TestingError
       end

      currency = FactoryGirl.create(:currency, :callback_url => 'https://www.whatnot.com')
      Currency.stub(:find_in_cache).with(currency.id, :do_lookup => true).and_return(currency)
      reward = FactoryGirl.create(:reward, :currency_id => currency.id)

      Downloader.stub(:get).and_raise(TestingError)
      Timecop.freeze(@now) do
        expect {
          get(:run_job, :message => reward.id)
        }.to raise_error(TestingError)
      end

      failures = Mc.get("send_currency_failures.#{@mc_time}")

      failures[@currency.id].should == Set.new.add(@reward.key)
      failures[currency.id].should == Set.new.add(reward.key)
    end

    it 'should not record more than 5000 errors' do
      Mc.increment_count(@fail_count_key, false, 1.week, 4998)

      Timecop.freeze(@now) do
        get(:run_job, :message => @reward.id) rescue TestingError
      end

      reward = FactoryGirl.create(:reward, :currency_id => @currency.id)
      @controller.instance_variable_set('@bad_callbacks', Set.new)

      Timecop.freeze(@now) do
        get(:run_job, :message => reward.id) rescue TestingError
      end

      failures = Mc.get("send_currency_failures.#{@mc_time}")
      failures[@currency.id].should == (Set.new.add(@reward.key))
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
      Downloader.should_receive(:get).and_return(@mock_response)
    end

    it 'should save the reward' do
      Currency.
        should_receive(:find_in_cache).
        with(@currency.id, {:do_lookup => true}).
        and_return(@currency)

      get(:run_job, :message => @reward.id)

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.to_i.should be_within(1).of(Time.zone.now.to_i)
      reward.send_currency_status.should == "200"
    end

    it 'creates a web request' do
      @mock_response.stub(:status).and_return(20)
      Timecop.freeze

      WebRequest.any_instance.should_receive(:put_values).with('send_currency_attempt',
        {:callback_url => "http://www.whatwhat.com?snuid=bill&currency=100&mac_address=",
        :http_status_code => 20,
        :http_response_time => 0.0,
        :reward_id => @reward.id,
        :publisher_app_id => @reward.publisher_app_id,
        :publisher_app_id => @reward.publisher_app_id,
        :currency_id => @reward.currency_id,
        :amount => @reward.currency_reward})

      get(:run_job, :message => @reward.id)
    end

    it 'should not reward twice' do
      get(:run_job, :message => @reward.id)

      reward = Reward.new(:key => @reward.key, :consistent => true)
      reward.sent_currency.to_i.should be_within(1).of(Time.zone.now.to_i)

      Currency.should_receive(:find_in_cache).never
      get(:run_job, :message => reward.id)
    end

    it "should work with a 200 status" do
      @mock_response.stub(:status).and_return(200)
      @web_request = WebRequest.new
      WebRequest.stub(:new).and_return(@web_request)
      Reward.stub(:find).and_return(@reward)

      get(:run_job, :message => @reward.id)
      @reward.send_currency_status.should == "200"
    end

    it "should work with a 500 status" do
      @mock_response.stub(:status).and_return(500)
      @web_request = WebRequest.new
      WebRequest.stub(:new).and_return(@web_request)

      get(:run_job, :message => @reward.id)
      assigns(:bad_callbacks).should include(@reward.currency_id)
    end

    
  end

  describe 'with TJ managed currency' do
    before :each do
      @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
      @currency.save!
      Currency.stub(:find_in_cache).and_return(@currency)
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

  describe "sending notifications" do
    before :each do
      @publisher_app.update_attributes('notifications_enabled' => true)
    end

    it "should send" do
      Sqs.should_receive(:send_message).with(QueueNames::CONVERSION_NOTIFICATIONS, @reward.id)
      get(:run_job, :message => @reward.id)
    end

    it 'should send with TJ managed currency' do
      @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
      @currency.save!
      Sqs.should_receive(:send_message).with(QueueNames::CONVERSION_NOTIFICATIONS, @reward.id)
      get(:run_job, :message => @reward.id)
    end

    it 'should not send with notifications disabled' do
      @publisher_app.update_attributes('notifications_enabled' => false)
      Sqs.should_not_receive(:send_message).with(QueueNames::CONVERSION_NOTIFICATIONS, @reward.id)
      get(:run_job, :message => @reward.id)
    end

    it 'should check to notify' do
      Offer.any_instance.should_receive(:should_notify_on_conversion?)
      Sqs.should_not_receive(:send_message).with(QueueNames::CONVERSION_NOTIFICATIONS, @reward.id)
      get(:run_job, :message => @reward.id)
    end
  end

  describe 'with callback url' do
    it 'should have verifier if currency has a secret key' do
      @currency.update_attribute(:secret_key, 'top secret')
      Currency.stub(:find_in_cache).and_return(@currency)

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
        should_receive(:get).
        with(callback_url, { :timeout => 20, :return_response => true }).
        and_return(@mock_response)

      get(:run_job, :message => @reward.id)
    end

    it 'should send offer data if currency says so' do
      app = FactoryGirl.create(:app)
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
        should_receive(:get).
        with(callback_url, { :timeout => 20, :return_response => true }).
        and_return(@mock_response)

      Offer.
        should_receive(:find_in_cache).
        with(offer.id, {:do_lookup => true}).
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
        should_receive(:get).
        with(callback_url, { :timeout => 20, :return_response => true }).
        and_return(@mock_response)

      get(:run_job, :message => @reward.id)
    end
  end

end
