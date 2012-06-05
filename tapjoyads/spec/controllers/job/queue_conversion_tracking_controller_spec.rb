require 'spec/spec_helper'

def click_message(click_key)
  { :click_key => click_key, :install_timestamp => Time.zone.parse('2010-04-15').to_f.to_s }.to_json
end

def expect_request_completes
  request = WebRequest.new(:time => Time.zone.now)
  WebRequest.should_receive(:new).and_return(request)
  request.should_receive(:save)
end

def expect_request_does_not_complete
  WebRequest.should_receive(:new).never
end

describe Job::QueueConversionTrackingController do
  before :each do
    fake_the_web
    Sqs.stub(:send_message)
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
  end

  context 'with a bad click id' do
    before :each do
      Click.should_receive(:find).and_return(nil)
    end

    it 'raises an error' do
      lambda {
        get(:run_job, :message => click_message('bad'))
      }.should raise_error(RuntimeError, /Click not found/)
    end
  end

  context 'missing a reward key' do
    before :each do
      @click = Factory(:click, :reward_key => nil, :clicked_at => Time.zone.now, :publisher_user_id => 'PUID')
      Click.should_receive(:find).and_return(@click)
    end

    it 'raises an error' do
      lambda {
        get(:run_job, :message => click_message(@click.key))
      }.should raise_error(RuntimeError, /missing reward key/)
    end
  end

  context 'with a valid click id' do
    before :each do
      @reward_uuid = UUIDTools::UUID.random_create.to_s
      @click = Factory(:click, :reward_key => @reward_uuid, :clicked_at => Time.zone.now, :publisher_user_id => 'PUID', :type => 'install')
      Click.should_receive(:find).and_return(@click)
      Reward.any_instance.stub(:update_realtime_stats)
    end

    def do_get
      get(:run_job, :message => click_message(@click.key))
    end

    it 'ignores already converted clicks' do
      @click.stub(:installed_at?).and_return(true)
      expect_request_does_not_complete
      do_get
    end

    it 'ignores old clicks (older than 2 days)' do
      @click.stub(:clicked_at).and_return(Time.zone.now - 5.days)
      expect_request_does_not_complete
      do_get
    end

    it 'ignores blocked clicks' do
      @click.stub(:block_reason?).and_return(true)
      expect_request_does_not_complete
      do_get
    end

    it 'blocks clicks from an invalid Playdom user ID' do
      Currency.any_instance.stub(:callback_url).and_return(Currency::PLAYDOM_CALLBACK_URL)
      @click.publisher_user_id = 'BADMOFO'
      @click.should_receive(:save)
      expect_request_does_not_complete
      do_get
      @click.block_reason.should match(/Playdom/)
    end

    it 'blocks clicks where the pubuser is associated with too many udids' do
      PublisherUser.any_instance.stub(:update!).and_return(false)
      @click.should_receive(:save)
      expect_request_does_not_complete
      do_get
      @click.block_reason.should match(/Udid/)
    end

    it 'blocks clicks from banned devices' do
      device = Device.new(:key => @click.udid)
      device.banned = true
      device.save
      expect_request_does_not_complete
      do_get
      @click.block_reason.should match(/Banned/)
    end

    context 'with multiple devices associated with the pubuser' do
      before :each do
        @this_device = Factory(:device)
        @other_device = Factory(:device)
        Device.stub(:new).and_return(@this_device, @other_device)
        pu = PublisherUser.for_click(@click)
        pu.update!(@this_device.key)
        pu.update!(@other_device.key)
      end

      it 'blocks clicks if any of the pubuser\'s devices are banned' do
        @other_device.banned = true
        expect_request_does_not_complete
        do_get
        @click.block_reason.should match(/Banned/)
      end

      context 'a single-complete offer' do
        before :each do
          offer = Offer.find_in_cache(@click.offer_id, true)
          offer.multi_complete = false
          Offer.stub(:find_in_cache).and_return(offer)
        end

        it 'blocks clicks if the pubuser already installed on another device' do
          @other_device.stub(:has_app?).and_return(true)
          expect_request_does_not_complete
          do_get
          @click.block_reason.should match(/AlreadyRewarded/)
        end
      end
    end

    context 'a paid app install on a jailbroken device' do
      before :each do
        @click.advertiser_amount = 20
        @click.tapjoy_amount = 30
        @offer = Offer.find_in_cache(@click.offer_id, true)
        @offer.stub(:is_paid?).and_return(true)
        Offer.stub(:find_in_cache).and_return(@offer)
        @device = Factory(:device)
        @device.is_jailbroken = true
        Device.stub(:new).and_return(@device)
      end

      it 'does not charge the advertizer (b/c the user likely did not pay)' do
        do_get
        @click.advertiser_amount = 0
        @click.tapjoy_amount = 50
      end

      it 'marks the click as jailbroken' do
        do_get
        @click.type.should == 'install_jailbroken'
      end

      it 'notifies via NewRelic' do
        Notifier.should_receive(:alert_new_relic).with { |err,msg,r,p| err == JailbrokenInstall }
        do_get
      end

      it 'continues processing the click' do
        expect_request_completes
        do_get
      end
    end

    context 'a featured ad' do
      before :each do
        @click.source = 'featured'
      end

      it 'marks the click as featured' do
        do_get
        @click.type.should == 'featured_install'
      end

      it 'continues processing the click' do
        expect_request_completes
        do_get
      end
    end

    context 'a reward already exists in the system' do
      before :each do
        Reward.any_instance.should_receive(:save!).raises(Simpledb::ExpectedAttributeError, 'test error')
      end

      it 'ignores the expectation failure and stops' do
        do_get
      end
    end

    context 'offer is rewarded and the currency has a callback url' do
      before :each do
        offer = Factory(:app).primary_offer
        offer.rewarded = true
        Offer.stub(:find_in_cache).and_return(offer)
        Currency.any_instance.stub(:callback_url).and_return('http://example.com')
      end

      it 'enqueues a send-currency message' do
        Sqs.should_receive(:send_message).with(QueueNames::SEND_CURRENCY, @reward_uuid)
        do_get
      end
    end

    it 'enqueues a create-conversions message' do
      Sqs.should_receive(:send_message).with(QueueNames::CREATE_CONVERSIONS, @reward_uuid)
      do_get
    end

    it 'updates reward stats' do
      Reward.any_instance.should_receive(:update_realtime_stats)
      do_get
    end

    context 'updating the reward stats fails' do
      before :each do
        Reward.any_instance.should_receive(:update_realtime_stats).raises(RuntimeError, 'Test error')
      end

      it 'notifies via NewRelic' do
        Notifier.should_receive(:alert_new_relic).with { |err,msg,r,p| err == RuntimeError }
        do_get
      end

      it 'continues processing' do
        expect_request_completes
        do_get
      end
    end

    it 'populates the installed_at field on the click' do
      do_get
      @click.installed_at.should == Time.zone.parse('2010-04-15')
    end

    context 'updating the last_run_time on the device' do
      before :each do
        @device = Factory(:device)
        Device.stub(:new).and_return(@device)
      end

      it 'updates the last_run_time for the advertiser app' do
        @device.stub(:has_app?).and_return(true)
        @device.stub(:last_run_time).and_return(Time.zone.now)
        @device.should_receive(:set_last_run_time).with(@click.advertiser_app_id)
        @device.should_receive(:save)
        do_get
      end

      context 'when the publisher app has never been run' do
        it 'updates the last_run_time for the publisher app' do
          @device.should_receive(:set_last_run_time).with(@click.advertiser_app_id)
          @device.should_receive(:has_app?).with(@click.publisher_app_id).and_return(false)
          @device.should_receive(:set_last_run_time).with(@click.publisher_app_id)
          do_get
        end
      end

      context 'when the publisher app has been run within the last week' do
        it 'does not update the last_run_time' do
          @device.should_receive(:set_last_run_time).with(@click.advertiser_app_id)
          @device.should_receive(:has_app?).with(@click.publisher_app_id).and_return(true)
          @device.should_receive(:last_run_time).with(@click.publisher_app_id).and_return(Time.zone.now - 2.days)
          @device.should_receive(:set_last_run_time).with(@click.publisher_app_id).never
          do_get
        end
      end

      context 'when the publisher app has a last_run_time of over a week ago' do
        it 'updates the last_run_time for the publisher app' do
          @device.should_receive(:set_last_run_time).with(@click.advertiser_app_id)
          @device.should_receive(:has_app?).with(@click.publisher_app_id).and_return(true)
          @device.should_receive(:last_run_time).with(@click.publisher_app_id).and_return(Time.zone.now - 2.weeks)
          @device.should_receive(:set_last_run_time).with(@click.publisher_app_id)
          do_get
        end
      end
    end

    it 'creates a WebRequest object' do
      expect_request_completes
      do_get
    end
  end
end
