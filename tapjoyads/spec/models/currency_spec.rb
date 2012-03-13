require 'spec_helper'

describe Currency do

  before :each do
    @currency = Factory.build(:currency)
    fake_the_web
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
        Resolv.stubs(:getaddress).raises(URI::InvalidURIError)
        @currency.callback_url = 'http://tapjoy' # invalid url
        @currency.save
        @currency.errors.on(:callback_url).should == 'is not a valid url'
      end
    end

    context 'when test devices are not valid' do
      before :each do
        @currency.stubs(:has_invalid_test_devices?).returns(true)
      end

      it 'is false' do
        @currency.should_not be_valid
        @currency.errors.on(:test_devices).should be_present
      end
    end
  end

  describe '#has_invalid_test_devices?' do
    before :each do
      @currency.test_devices = Factory.next(:guid) * 5
    end

    context 'when one test device key is too long' do
      it 'returns true' do
        @currency.has_invalid_test_devices?.should be_true
      end
    end

    context 'fixing bad list' do
      it 'returns false' do
        @currency.get_test_device_ids # load once
        @currency.test_devices = Factory.next(:guid)
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
        @currency2.errors.on(:callback_url).should == 'cannot be managed if the app has multiple currencies'
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
        @offer = Factory(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer).should == 0
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = Factory(:app, :partner => @currency.partner).primary_offer
        @offer.update_attribute(:payment, 25)
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer).should == 0
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer).should == 12
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = Factory(:app)
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer, @displayer_app).should == 0
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_publisher_amount(@offer, @displayer_app).should == 0
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = Factory(:app).primary_offer
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
        @offer = Factory(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == 0
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = Factory(:app, :partner => @currency.partner).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == 0
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == -25
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = Factory(:app)
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == -25
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_advertiser_amount(@offer).should == -25
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = Factory(:app).primary_offer
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
        @offer = Factory(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = Factory(:app, :partner => @currency.partner).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer).should == 13
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = Factory(:app)
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer, @displayer_app).should == 13
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_tapjoy_amount(@offer, @displayer_app).should == 13
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = Factory(:app).primary_offer
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
        @offer = Factory(:rating_offer).primary_offer
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 15
      end
    end

    context 'when given an offer from the same partner' do
      before :each do
        @offer = Factory(:app, :partner => @currency.partner).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 25
      end
    end

    context 'when given any other offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 12
      end
    end

    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = Factory(:app)
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 12
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 12
      end
    end

    context 'when given a direct-pay offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.payment = 100
        @offer.reward_value = 50
        @offer.direct_pay = Offer::DIRECT_PAY_PROVIDERS.first
      end

      it 'returns the correct amount' do
        @currency.get_reward_amount(@offer).should == 50
      end
    end
  end

  describe '#get_displayer_amount' do
    context 'when given a 3-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = Factory(:app)
      end

      it 'returns the correct amount' do
        @currency.get_displayer_amount(@offer, @displayer_app).should == 12
      end
    end

    context 'when given a 2-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'returns the correct amount' do
        @currency.get_displayer_amount(@offer, @displayer_app).should == 12
      end
    end
  end

  describe '#set_values_from_partner_and_reseller' do
    context 'before create' do
      before :each do
        partner = Factory(:partner)
        partner.rev_share = 0.42
        partner.direct_pay_share = 0.8
        partner.disabled_partners = 'foo'
        partner.offer_whitelist = 'bar'
        partner.use_whitelist = true
        @currency.partner = partner
      end

      it 'copies values from its partner' do
        @currency.save!
        @currency.spend_share.should == 0.42
        @currency.direct_pay_share.should == 0.8
        @currency.disabled_partners.should == 'foo'
        @currency.offer_whitelist.should == 'bar'
        @currency.use_whitelist.should == true
      end
    end
  end

end
