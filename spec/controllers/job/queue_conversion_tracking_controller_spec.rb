require 'spec_helper'

def click_message(click_key)
  { :click_key => click_key, :install_timestamp => Time.zone.parse('2010-04-15').to_f.to_s }.to_json
end

INSTRUCTION_VIEWED_AT = Time.zone.parse('2010-01-01 00:00:00')
INSTRUCTION_CLICKED_AT = Time.zone.parse('2010-01-01 00:05:00')
def instruction_click_message(click_key)
  { :click_key => click_key,
    :offer_instruction_click => {
      :viewed_at => INSTRUCTION_VIEWED_AT.to_f,
      :clicked_at => INSTRUCTION_CLICKED_AT.to_f
    }
  }.to_json
end

def expect_request_completes
  reward_request = WebRequest.new(:time => Time.zone.now)
  reward_request.should_receive(:save)
  reward_request.should_receive(:advertiser_balance=).with(0)

  conversion_attempt_request = WebRequest.new(:time => Time.zone.now)
  conversion_attempt_request.should_receive(:save)

  WebRequest.should_receive(:new).and_return(reward_request, conversion_attempt_request)
end

def expect_request_does_not_complete
  WebRequest.should_receive(:new).never
end

describe Job::QueueConversionTrackingController do
  before :each do
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
      @click = FactoryGirl.create(:click, :reward_key => nil, :clicked_at => Time.zone.now, :publisher_user_id => 'PUID')
      Currency.stub(:find_in_cache).with(@click.currency_id, :do_lookup => true).and_return(Currency.find(@click.currency_id))
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
      @click = FactoryGirl.create(:click, :reward_key => @reward_uuid, :clicked_at => Time.zone.now, :publisher_user_id => 'PUID', :type => 'install')
      Currency.stub(:find_in_cache).with(@click.currency_id, :do_lookup => true).and_return(Currency.find(@click.currency_id))
      Click.should_receive(:find).and_return(@click)
      Reward.any_instance.stub(:update_realtime_stats)
      Reward.any_instance.stub(:advertiser_amount).and_return(-50)
    end

    def do_get
      get(:run_job, :message => click_message(@click.key))
    end

    def do_instruction_get
      get(:run_job, :message => instruction_click_message(@click.key))
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

    context 'for clicks that are deemed too risky based on risk scores and rules' do
      before :each do
        @checker = double("ConversionChecker")
        @checker.stub(:acceptable_risk?).and_return(false)
        @checker.stub(:risk_message).and_return('test failure')
        ConversionChecker.should_receive(:new).and_return(@checker)
        @click.should_receive(:save)
      end

      it 'blocks the click' do
        do_get
        @click.block_reason.should == 'test failure'
      end

      context 'but is being force converted' do
        before :each do
          @click.stub(:force_convert).and_return(true)
        end

        it 'allows the conversion' do
          @checker.should_receive(:process_conversion)
          expect_request_completes
          do_get
        end
      end
    end

    context 'a paid app install on a jailbroken device' do
      before :each do
        @click.advertiser_amount = 20
        @click.tapjoy_amount = 30        
        @offer = Offer.find_in_cache(@click.offer_id, :do_lookup => true)
        @offer.stub(:is_paid?).and_return(true)
        Offer.stub(:find_in_cache).and_return(@offer)
        @device = FactoryGirl.create(:device)
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

    it 'creates a reward' do
      reward = FactoryGirl.create(:reward)
      Reward.stub(:new).and_return(reward)
      reward.stub(:is_new).and_return(true)
      reward.should_receive(:save!)
      do_get
    end

    context 'a reward already exists in the system' do
      before :each do
        @reward = FactoryGirl.create(:reward)
        Reward.stub(:new).and_return(@reward)
        @reward.stub(:is_new).and_return(false)
      end

      it 'does not try to update reward' do
        @reward.should_not_receive(:save!)
        do_get
      end
      it 'does not create another WebRequest' do
        request = WebRequest.new(:time => Time.zone.now)
        WebRequest.should_receive(:new).once().and_return(request);
        do_get
      end
    end

    context 'a reward is simultaneously created' do
      it 'does not create another WebRequest' do
        Reward.any_instance.stub(:save!).and_raise(Simpledb::ExpectedAttributeError)
        request = WebRequest.new(:time => Time.zone.now)
        WebRequest.should_receive(:new).once().and_return(request);
        do_get
      end
    end

    context 'offer is rewarded and the currency has a callback url' do
      before :each do
        offer = FactoryGirl.create(:app).primary_offer
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
        Reward.any_instance.should_receive(:update_realtime_stats).and_raise(RuntimeError.new 'Test error')
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
        @device = FactoryGirl.create(:device)
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

    it 'does not blow up if Click#update_partner_live_dates! fails' do
      @click.stub(:update_partner_live_dates!).and_raise(RuntimeError)
      expect_request_completes
      do_get
    end

    it 'creates a WebRequest object' do
      expect_request_completes
      do_get
    end

    context 'invoked from offer instruction' do
      before :each do
        do_instruction_get
      end

      it "should set instruction_viewed_at for the click", :instruction do
        @click.instruction_viewed_at.should == INSTRUCTION_VIEWED_AT
      end

      it "should set instruction_clicked_at for the click", :instruction do
        @click.instruction_clicked_at.should == INSTRUCTION_CLICKED_AT
      end

      it "should set instruction_viewed_at for the rewar", :instruction do
        reward = Reward.find(@click.reward_key)
        reward.instruction_viewed_at.should == INSTRUCTION_VIEWED_AT
      end
    end
  end
end
