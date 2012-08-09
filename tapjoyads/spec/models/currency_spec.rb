require 'spec_helper'

describe Currency do

  before :each do
    @currency = Factory.build(:currency)
  end

  describe '.belongs_to' do
    it { should belong_to(:app) }
    it { should belong_to(:partner) }
  end

  describe '#valid?' do
    it { should validate_presence_of(:app) }
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:callback_url) }
    it { should validate_numericality_of(:conversion_rate) }
    it { should validate_numericality_of(:initial_balance) }
    it { should validate_numericality_of(:spend_share) }
    it { should validate_numericality_of(:direct_pay_share) }
    it { should validate_numericality_of(:max_age_rating) }

    context 'when not tapjoy-managed' do
      it 'validates callback url' do
        Resolv.stub(:getaddress).and_raise(URI::InvalidURIError)
        @currency.callback_url = 'http://tapjoy' # invalid url
        @currency.save
        @currency.errors[:callback_url].join.should == 'is not a valid url'
      end
    end

    context 'when test devices are not valid' do
      before :each do
        @currency.stub(:has_invalid_test_devices?).and_return(true)
      end

      it 'is false' do
        @currency.should_not be_valid
        @currency.errors[:test_devices].should be_present
      end
    end
  end

  describe '#has_invalid_test_devices?' do
    before :each do
      @currency.test_devices = FactoryGirl.generate(:guid) * 5
    end

    context 'when one test device key is too long' do
      it 'returns true' do
        @currency.has_invalid_test_devices?.should be_true
      end
    end

    context 'fixing bad list' do
      it 'returns false' do
        @currency.get_test_device_ids # load once
        @currency.test_devices = FactoryGirl.generate(:guid)
        @currency.has_invalid_test_devices?.should be_false
      end
    end
  end

  describe '#has_special_callback?' do
    context 'when having special callbacks' do
      it 'returns true' do
        Currency::SPECIAL_CALLBACK_URLS.each do |url|
          @currency.callback_url = url
          @currency.should be_has_special_callback
        end
      end

      it 'does not allow multiple currencies' do
        @currency2 = Factory.build(:currency, :app_id => @currency.app_id, :partner_id=> @currency.partner_id)
        @currency.save
        @currency2.save
        @currency2.errors[:callback_url].join.should == 'cannot be managed if the app has multiple currencies'
      end
    end

    context 'when not having special callbacks' do
      it 'returns false' do
        @currency.callback_url = 'http://example.com/foo'
        @currency.should_not be_has_special_callback
      end

      it 'does allow multiple currencies' do
        @currency.callback_url = 'http://example.com/foo'
        @currency2 = Factory.build(:currency, :app_id => @currency.app_id, :partner_id=> @currency.partner_id, :callback_url => 'http://example.com/foo')
        @currency.save
        @currency2.save.should == true
      end
    end
  end

  describe '#get_publisher_amount' do
    context 'when given a rating offer' do
      before :each do
        @offer = FactoryGirl.create(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer).should == 0
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = FactoryGirl.create(:app, :partner => @currency.partner).primary_offer
        @offer.update_attribute(:payment, 25)
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer).should == 0
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer).should == 12
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = FactoryGirl.create(:app)
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer, @displayer_app).should == 0
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer, @displayer_app).should == 0
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.payment = 100
        @offer.reward_value = 50
        @offer.direct_pay = Offer::DIRECT_PAY_PROVIDERS.first
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer).should == 100
      end
    end
  end

  describe '#get_advertiser_amount' do
    context 'when given a RatingOffer' do
      before :each do
        @offer = FactoryGirl.create(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == 0
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = FactoryGirl.create(:app, :partner => @currency.partner).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == 0
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == -25
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = FactoryGirl.create(:app)
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == -25
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == -25
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.payment = 100
        @offer.reward_value = 50
        @offer.direct_pay = Offer::DIRECT_PAY_PROVIDERS.first
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == -100
      end
    end
  end

  describe '#get_tapjoy_amount' do
    context 'when given a RatingOffer' do
      before :each do
        @offer = FactoryGirl.create(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = FactoryGirl.create(:app, :partner => @currency.partner).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer).should == 13
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = FactoryGirl.create(:app)
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer, @displayer_app).should == 13
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer, @displayer_app).should == 13
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.payment = 100
        @offer.reward_value = 50
        @offer.direct_pay = Offer::DIRECT_PAY_PROVIDERS.first
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end
    end
  end

  describe '#get_reward_amount' do
    context 'when given a RatingOffer' do
      before :each do
        @offer = FactoryGirl.create(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 15
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = FactoryGirl.create(:app, :partner => @currency.partner).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 25
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 12
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = FactoryGirl.create(:app)
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 12
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 12
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.payment = 100
        @offer.reward_value = 50
        @offer.direct_pay = Offer::DIRECT_PAY_PROVIDERS.first
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 50
      end
    end

    context 'when given a low offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 1})
      end

      it 'rounds up to 1' do
        @currency.get_reward_amount(@offer).should == 1
      end
    end
  end

  describe '#get_displayer_amount' do
    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = FactoryGirl.create(:app)
      end

      it 'returns the correct amount' do
        @currency.get_displayer_amount(@offer, @displayer_app).should == 12
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_displayer_amount(@offer, @displayer_app).should == 12
      end
    end
  end

  describe '#set_promoted_offers' do
    context 'before create' do
      before :each do
        offer1 = FactoryGirl.create(:app).primary_offer
        offer2 = FactoryGirl.create(:app).primary_offer
        original_currency = FactoryGirl.create(:currency)
        @promoted_offer_list = [ offer1.id, offer2.id ]

        app = FactoryGirl.create(:app)
        original_currency.promoted_offers = @promoted_offer_list
        app.stub(:currencies).and_return([original_currency])

        @currency.app = app
        @currency.callback_url = 'http://example.com/foo'
      end

      it 'copies the promoted offers from existing currencies' do
        @currency.save!
        @currency.get_promoted_offers.should == Set.new(@promoted_offer_list)
      end
    end
  end

  describe '#set_values_from_partner_and_reseller' do
    context 'before create' do
      before :each do
        partner = FactoryGirl.create(:partner)
        partner.rev_share = 0.42
        partner.direct_pay_share = 0.8
        partner.disabled_partners = 'foo'
        partner.offer_whitelist = 'bar'
        partner.use_whitelist = true
        @currency.partner = partner
      end

      it 'copies values from its partner' do
        Timecop.freeze(Time.parse('2012-08-01')) do # forcing new algorithm
          @currency.save!
          @currency.spend_share.should == 0.3822
          @currency.direct_pay_share.should == 0.8
          @currency.disabled_partners.should == 'foo'
          @currency.offer_whitelist.should == 'bar'
          @currency.use_whitelist.should == true
        end
      end
    end

    context 'when approved' do
      it 'should set currency to Tapjoy Enabled' do
        @currency.tapjoy_enabled.should_not be_true
        @currency.after_approve(nil)
        @currency.reload
        @currency.tapjoy_enabled.should be_true
      end
    end

    context 'when rejected then updated' do
      it 'should be pending' do
        approval = mock()
        approval.should_receive(:destroy).at_least(:once)
        @currency.stub(:approval).and_return(approval)
        @currency.stub(:rejected?).and_return(true)
        @currency.run_callbacks :update
      end
    end
  end

  describe '#create_deeplink_offer' do
    it 'should create a corresponding DeeplinkOffer' do
      @currency.save!
      @currency.enabled_deeplink_offer_id.should_not be_nil
      dl = DeeplinkOffer.find_by_id(@currency.enabled_deeplink_offer_id)
      dl.currency.should == @currency
    end
  end

  describe '#approve_on_tapjoy_enabled' do
    context 'when tapjoy_enabled is toggled true' do
      it 'will call approve!' do
        @currency.stub(:approval).and_return(stub('approval', :state => 'pending'))
        @currency.should_receive(:approve!).once
        @currency.tapjoy_enabled = true
        @currency.run_callbacks :update
      end
    end

    context 'when approvals are not present' do
      it 'will do nothing' do
        @currency.stub(:approval).and_return(nil)
        @currency.should_receive(:approve!).never
        @currency.tapjoy_enabled = true
        @currency.run_callbacks :update
      end
    end
  end

  describe '#approve!' do
    it 'calls approve!(true) on approval attribute' do
      mock_approval = mock('approval')
      mock_approval.should_receive(:approve!).with(true).once
      @currency.stub(:approval).and_return(mock_approval)
      @currency.approve!
    end
  end

  describe '#create_deeplink_offer' do
    it 'should create a corresponding DeeplinkOffer' do
      @currency.save!
      @currency.enabled_deeplink_offer_id.should_not be_nil
      dl = DeeplinkOffer.find_by_id(@currency.enabled_deeplink_offer_id)
      dl.currency.should == @currency
    end
  end

  describe '#dashboard_app_currency_url' do
    before :each do
      @currency = FactoryGirl.create :currency
    end

    it 'matches URL for Rails app_currency_url helper' do
      @currency.dashboard_app_currency_url.should ==  "#{URI.parse(DASHBOARD_URL).scheme}://#{URI.parse(DASHBOARD_URL).host}/apps/#{@currency.app_id}/currencies/#{@currency.id}"
    end
  end

  describe '#cache_by_app_id' do
    context 'tapjoy_enabled = true' do
      before :each do
        @currency = FactoryGirl.create(:currency)
      end

      it 'caches currencies before saving them' do
        Currency.any_instance.should_receive(:run_callbacks).with(:cache)
        Mc.should_receive(:distributed_put)
        @currency.send(:cache_by_app_id)
      end
    end

    context 'tapjoy_enabled = false' do
      before :each do
        @currency = FactoryGirl.create(:currency)
        @currency.tapjoy_enabled = false
        @currency.save
      end

      it 'should have an empty array returned when tapjoy_enabled is false' do
        Currency.any_instance.should_not_receive(:run_callbacks).with(:cache) #since blank array currencies
        Mc.should_receive(:distributed_put).with("mysql.app_currencies.#{@currency.app_id}.#{Currency.acts_as_cacheable_version}", [], false, 1.day)
        @currency.send(:cache_by_app_id)
      end
    end
  end

  describe '#charges?' do
    context 'advertiser amount is not 0' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
      end

      it 'returns true because there is a charge to the advertiser for an offer' do
        @currency.charges?(@offer).should == true
      end
    end

    context 'advertiser amount is 0' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @currency.stub(:partner_id).and_return(@offer.partner_id)
      end

      it 'returns false becauses there is no charge to the advertiser for an offer' do
        @currency.charges?(@offer).should == false
      end
    end
  end
end
