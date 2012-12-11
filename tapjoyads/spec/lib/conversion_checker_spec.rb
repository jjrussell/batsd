require 'spec_helper'

describe ConversionChecker do
  before :each do
    @reward_uuid = UUIDTools::UUID.random_create.to_s
    @click = FactoryGirl.create(:click, :reward_key => @reward_uuid, :clicked_at => Time.zone.now, :publisher_user_id => 'PUID', :type => 'install', :advertiser_amount => -50)
  end

  describe '#acceptable_risk?' do
    it 'returns true if none of the blocking criteria are met' do
      checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
      checker.should be_acceptable_risk
      checker.risk_message.should be_nil
    end

    it 'returns false for a pubuser associated with too many TapjoyDeviceIDs' do
      PublisherUser.any_instance.stub(:update!).and_return(false)
      checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
      checker.should_not be_acceptable_risk
      checker.risk_message.should match(/TapjoyDeviceIDs/)
    end

    it 'returns false for banned devices' do
      device = Device.new(:key => @click.tapjoy_device_id)
      device.banned = true
      device.save
      checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
      checker.should_not be_acceptable_risk
      checker.risk_message.should match(/Banned/)
    end

    it 'returns false for suspended devices' do
      device = Device.new(:key => @click.tapjoy_device_id)
      device.suspend!(24)
      checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
      checker.should_not be_acceptable_risk
      checker.risk_message.should match(/Suspended/)
    end

    context 'with multiple devices associated with the pubuser' do
      before :each do
        @this_device = FactoryGirl.create(:device)
        @other_device = FactoryGirl.create(:device)
        Device.stub(:new).and_return(@this_device, @other_device)
        pu = PublisherUser.for_click(@click)
        pu.update!(@this_device.key)
        pu.update!(@other_device.key)
      end

      it 'returns false if any of the pubuser\'s devices are banned' do
        @other_device.banned = true
        checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
        checker.should_not be_acceptable_risk
        checker.risk_message.should match(/Banned/)
      end

      it 'returns false if any of the pubuser\'s devices are suspended' do
        @other_device.suspend!(24)
        checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
        checker.should_not be_acceptable_risk
        checker.risk_message.should match(/Suspended/)
      end

      context 'a single-complete offer' do
        before :each do
          offer = Offer.find_in_cache(@click.offer_id, :do_lookup => true)
          offer.multi_complete = false
          Offer.stub(:find_in_cache).and_return(offer)
        end

        it 'returns false if the pubuser already installed on another device' do
          @other_device.stub(:has_app?).and_return(true)
          checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
          checker.should_not be_acceptable_risk
          checker.risk_message.should match(/AlreadyRewarded/)
        end
      end
    end

    context 'when risk management is not enabled for partner' do
      it 'returns true' do
        Currency.any_instance.stub(:partner_enable_risk_management?).and_return(false)
        checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
        checker.should be_acceptable_risk
      end
    end

    context 'when risk management is enabled for partner' do
      before :each do
        @now = Time.now
        Timecop.freeze(@now)
        @device = FactoryGirl.create(:device)
        Device.stub(:new).and_return(@device)
        Currency.any_instance.stub(:partner_enable_risk_management?).and_return(true)
        @checker = ConversionChecker.new(@click, ConversionAttempt.new(:key => @reward_uuid))
      end

      context 'and conversion risk score exceeds high threshold' do
        it 'returns false' do
          RiskScore.any_instance.stub(:too_risky?).and_return(true)
          @checker.should_not be_acceptable_risk
          @checker.risk_message.should match(/risk is too high/)
        end
      end

      context 'and rule evaluation returns BLOCK action' do
        it 'returns false' do
          actions = Set.new.add('BLOCK')
          RiskActionSet.any_instance.stub(:actions).and_return(actions)
          @checker.should_not be_acceptable_risk
          @checker.risk_message.should match(/risk is too high/)
        end
      end

      context 'and rule evaluation returns BAN action' do
        it 'bans device' do
          actions = Set.new.add('BAN')
          RiskActionSet.any_instance.stub(:actions).and_return(actions)
          @checker.acceptable_risk?
          @device.should be_banned
        end
      end

      context 'and rule evaluation returns SUSPEND24 action' do
        it 'suspends device for 24 hours' do
          actions = Set.new.add('SUSPEND24')
          RiskActionSet.any_instance.stub(:actions).and_return(actions)
          @checker.acceptable_risk?
          @device.should be_suspended
          Timecop.freeze(@now+25.hours)
          @device.should_not be_suspended
        end
      end

      context 'and rule evaluation returns SUSPEND72 action' do
        it 'suspends device for 72 hours' do
          actions = Set.new.add('SUSPEND72')
          RiskActionSet.any_instance.stub(:actions).and_return(actions)
          @checker.acceptable_risk?
          @device.should be_suspended
          Timecop.freeze(@now+73.hours)
          @device.should_not be_suspended
        end
      end

      after :each do
        Timecop.return
      end
    end
  end
end
