require 'spec_helper'

describe Currency do

  before :each do
    @currency = Factory.build(:currency)
  end

  describe '.belongs_to' do
    it { should belong_to(:app) }
    it { should belong_to(:partner) }
  end

  describe '.has_one' do
    it do
      # TODO: add a required() method to Shoulda::Matchers::ActiveRecord::AssociationMatcher
      matcher = have_one(:deeplink_offer)
      should matcher
      matcher.send(:reflection).options[:required].should be_true
    end
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

    context 'when the currency is non-rewarded' do
      before :each do
        @non_rewarded = Factory.create(:non_rewarded)
        @non_rewarded.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
        @non_rewarded.save
      end

      it 'is false' do
        @non_rewarded.should_not be_valid
      end

      it 'ensures that the callbacK_url cannot change from NO_CALLBACK' do
        @non_rewarded.errors[:callback_url].join.should == "must be set to #{Currency::NO_CALLBACK_URL} for non-rewarded currencies"
      end
    end

    context 'when not tapjoy-managed' do
      it 'validates callback url syntax' do
        Resolv.stub(:getaddress).and_raise(URI::InvalidURIError)
        @currency.callback_url = 'http://tapjoy' # invalid url
        @currency.save
        @currency.errors[:callback_url].join.should == 'is not a valid url'
      end

      it 'validates DNS resolution of callback hostname' do
        Resolv.stub(:getaddress).and_raise(Resolv::ResolvError)
        @currency.callback_url = 'http://someundefinedsubdomain.tapjoy.com' # unresolvable url
        @currency.save
        @currency.errors[:callback_url].join.should == 'host cannot be resolved'
      end
    end

    context "offer_filter" do
      context "offer_filter direct assignment" do
        before :each do
          @currency.use_offer_filter_selections = false
        end

        it "should retain offer_filter if offer_filter_selections is nil", :offer_filter do
          @currency.offer_filter_selections = nil
          @currency.offer_filter = "ActionOffer,GenericOffer,Coupon"
          @currency.save
          @currency.offer_filter.should == "ActionOffer,GenericOffer,Coupon"
        end

        it "should retain offer_filter even if offer_filter_selections is not nil", :offer_filter do
          @currency.offer_filter_selections = ["GenericOffer"]
          @currency.offer_filter = "ActionOffer,GenericOffer,Coupon"
          @currency.save
          @currency.offer_filter.should == "ActionOffer,GenericOffer,Coupon"
        end
      end

      context "offer_filter assignment through UI" do
        before :each do
          @currency.use_offer_filter_selections = true
          @currency.offer_filter = "Coupon"
        end

        it "validates known offer types", :offer_filter do
          @currency.offer_filter_selections = ["ActionOffer", "GenericOffer"]
          @currency.save
          @currency.offer_filter.should == "ActionOffer,GenericOffer"
        end

        it "invalidates unknown offer types", :offer_filter do
          @currency.offer_filter_selections = ["ActionOffer,NoSuchOffer"]
          @currency.save
          @currency.errors[:offer_filter].join.should == "contains invalid offer types NoSuchOffer"
        end

        it "invalidates obsolete offer types", :offer_filter do
          @currency.offer_filter_selections = ["ActionOffer,OfferpalOffer"]
          @currency.save
          @currency.errors[:offer_filter].join.should == "contains invalid offer types OfferpalOffer"
        end

        it "should convert offer_filter_selections to offer_filter", :offer_filter do
          @currency.offer_filter_selections = ["ActionOffer", "GenericOffer"]
          @currency.save
          @currency.offer_filter.should == "ActionOffer,GenericOffer"
        end

        it "should set offer_filter to nil if there's no offers from offer_filter_selections", :offer_filter do
          @currency.offer_filter_selections = nil
          @currency.save
          @currency.offer_filter.should be_nil
        end

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

    context 'when the conversion_rate is about to be changed' do
      before :each do
        Currency.any_instance.stub(:approve!).and_return(true)
        @app = FactoryGirl.create(:app)
      end

      context 'from nonzero to zero' do
        before :each do
          @currency = FactoryGirl.create(:currency)
          @currency.should be_valid
          @currency.conversion_rate = 0
          @currency.save
        end

        it 'this validation fails' do
          @currency.should_not be_valid
          @currency.errors[:conversion_rate].should be_present
        end
      end

      context 'from zero to nonzero' do
        before :each do
          @currency = FactoryGirl.create(:non_rewarded)
          @currency.should be_valid
          @currency.conversion_rate = FactoryGirl.generate(:integer) ** 2 + 1 #in case it generates a negative or 0
          @currency.save
        end

        it 'this validation fails' do
          @currency.should_not be_valid
          @currency.errors[:conversion_rate].should be_present
        end
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

  describe '#get_raw_reward_value' do
    context 'tricky rounding' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        @offer.update_attributes({:payment => 50})
        @currency.conversion_rate = 270_000
        @currency.spend_share = 0.595
      end

      it 'matches the amount we send pubs' do
        currency_amount = @currency.get_raw_reward_value(@offer)
        pub_amount = @currency.get_publisher_amount(@offer) / 100.0
        currency_amount.should == pub_amount * @currency.conversion_rate
      end
    end
  end

  describe '#currency_conversion_rate' do
    context 'not exchange rate enabled' do
      before :each do
        @currency.conversion_rate_enabled = false
      end
      it 'should return the currency\'s conversion rate' do
        @currency.currency_conversion_rate(@offer).should == @currency.conversion_rate
      end
    end

    context 'conversion rate enabled' do
      before :each do
        @currency.conversion_rate_enabled = true
        @currency.conversion_rate = 5
        @currency.save
        Currency.stub(:find).and_return(@currency)
        @offer = FactoryGirl.create(:app).primary_offer
        @conversion_rate = FactoryGirl.create(:conversion_rate, :rate => 10, :minimum_offerwall_bid => 1, :currency_id => @currency.id)
        @conversion_rate2 = FactoryGirl.create(:conversion_rate, :rate => 30, :minimum_offerwall_bid => 2, :currency_id => @currency.id)
        @conversion_rate3 = FactoryGirl.create(:conversion_rate, :rate => 70, :minimum_offerwall_bid => 3, :currency_id => @currency.id)
        @currency.stub(:all_conversion_rates).and_return([@conversion_rate, @conversion_rate2, @conversion_rate3])
      end
      context 'should return the conversion rate based on the publisher amount closest to the floored minimum offerwall bid' do
        it 'returns currency\'s conversion rate if the publisher amount is less than all the conversion rates minimum_offerwall_bids' do
          @currency.stub(:get_publisher_amount).and_return(0)
          @currency.currency_conversion_rate(@offer).should == @currency.conversion_rate
        end
        it 'returns conversion_rate1 conversion rate' do
          @currency.stub(:get_publisher_amount).and_return(1.2)
          @currency.currency_conversion_rate(@offer).should == @conversion_rate.rate
        end
        it 'returns conversion_rate2 conversion rate' do
          @currency.stub(:get_publisher_amount).and_return(2.9)
          @currency.currency_conversion_rate(@offer).should == @conversion_rate2.rate
        end
        it 'returns conversion_rate3 conversion rate when the value is exactly on the minimum_offerwall_bid' do
          @currency.stub(:get_publisher_amount).and_return(3)
          @currency.currency_conversion_rate(@offer).should == @conversion_rate3.rate
        end
        it 'returns conversion_rate3 conversion rate (highest minimum_offerwall_bid) when the publisher amount is greater than all the minimum_offerwall_bid values' do
          @currency.stub(:get_publisher_amount).and_return(13)
          @currency.currency_conversion_rate(@offer).should == @conversion_rate3.rate
        end
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
        @currency.save!
        @currency.spend_share.should == (0.42 * SpendShare.current_ratio)
        @currency.direct_pay_share.should == 0.8
        @currency.disabled_partners.should == 'foo'
        @currency.offer_whitelist.should == 'bar'
        @currency.use_whitelist.should == true
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

  describe '#get_test_device_ids' do
    context 'after set with string' do
      it 'returns ids a Set' do
        devs = Set.new(['a', 'b'])
        @currency.test_devices = devs.to_a.join(';')
        @currency.get_test_device_ids.should == devs
      end
    end

    context 'after set with array' do
      it 'returns ids a Set' do
        devs = Set.new(['a', 'b'])
        @currency.test_devices = devs.to_a
        @currency.get_test_device_ids.should == devs
       end
    end
  end

  describe '#test_devices=' do
    context 'with array as arg' do
      it 'encodes field' do
        devs = ['a', 'b']
        @currency.test_devices = devs
        @currency.test_devices.should == Set.new(devs)
      end
    end

    context 'with string as arg' do
      it 'stores string as field' do
        devs = ['a', 'b']
        @currency.test_devices = devs.join(';')
        @currency.test_devices.should == Set.new(devs)
      end
    end

    context 'with Set as arg' do
      it 'stores string as field' do
        devs = Set.new(['a', 'b'])
        @currency.test_devices = devs
        @currency.test_devices.should == devs
      end
    end
  end

  describe '#currency_sale_multiplier' do
    before :each do
      @currency.save
    end
    context 'with an active currency sale' do
      before :each do
        @currency_sale = FactoryGirl.create(:currency_sale, :start_time => Time.zone.now - 30.minutes, :end_time => Time.zone.now + 3.days, :currency_id => @currency.id, :multiplier => 3.0)
        @currency.stub_chain(:currency_sales, :active_or_future).and_return([@currency_sale])
      end
      it 'should return the multiplier field from currency sale' do
        @currency.currency_sale_multiplier.should == @currency_sale.multiplier
      end
    end
    context 'without an active currency sale' do
      it 'should return 1' do
        @currency.currency_sale_multiplier.should == 1
      end
    end
  end

  describe '#active_and_future_sales' do
    before :each do
      @currency.save
      @currency_sale = FactoryGirl.create(:currency_sale, :start_time => Time.zone.now - 30.minutes, :end_time => Time.zone.now + 1.day, :currency_id => @currency.id, :multiplier => 3.0, :message_enabled => false, :message => nil)
      @currency_sale2 = FactoryGirl.create(:currency_sale, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 4.days, :currency_id => @currency.id, :multiplier => 2.0, :message_enabled => true, :message => 'test')
      @currency.stub_chain(:currency_sales, :active_or_future).and_return([@currency_sale, @currency_sale2])
      @range_hash = RangedHash.new(@currency_sale.start_time..@currency_sale.end_time => { :multiplier => @currency_sale.multiplier, :message => @currency_sale.message, :message_enabled => @currency_sale.message_enabled },
                                   @currency_sale2.start_time..@currency_sale2.end_time => { :multiplier => @currency_sale2.multiplier, :message => @currency_sale2.message, :message_enabled => @currency_sale2.message_enabled })
    end
    it 'returns a ranged hash' do
      @currency.active_and_future_sales[:ranges].should == @range_hash[:ranges]
    end
    context 'active sale' do
      it 'returns a hash of the multiplier, message, and message_enabled attributes of the current time' do
        @currency.active_and_future_sales[Time.zone.now].should == { :multiplier => @currency_sale.multiplier, :message => @currency_sale.message, :message_enabled => @currency_sale.message_enabled }
      end
    end
    context 'future sale' do
      it 'returns a hash of the multiplier, message, and message_enabled attributes of the current time' do
        @currency.active_and_future_sales[Time.zone.now+3.days].should == { :multiplier => @currency_sale2.multiplier, :message => @currency_sale2.message, :message_enabled => @currency_sale2.message_enabled }
      end
    end
  end
end
