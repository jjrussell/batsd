require 'spec_helper'

describe Currency do
  before :each do
    fake_the_web
  end

  subject { Factory(:currency) }

  context 'when associating' do
    it { should belong_to(:app) }
    it { should belong_to(:partner) }
  end

  context 'when validating' do
    it { should validate_presence_of(:app) }
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:callback_url) }
    it { should validate_numericality_of(:conversion_rate) }
    it { should validate_numericality_of(:initial_balance) }
    it { should validate_numericality_of(:spend_share) }
    it { should validate_numericality_of(:direct_pay_share) }
    it { should validate_numericality_of(:max_age_rating) }
  end

  context 'A Currency' do
    before :each do
      @currency = Factory.build(:currency)
    end

    context 'when dealing with a RatingOffer' do
      before :each do
        @offer = Factory(:rating_offer).primary_offer
      end

      it 'calculates publisher amounts' do
        @currency.get_publisher_amount(@offer).should == 0
      end

      it 'calculates advertiser amounts' do
        @currency.get_advertiser_amount(@offer).should == 0
      end

      it 'calculates tapjoy amounts' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end

      it 'calculates reward amounts' do
        @currency.get_reward_amount(@offer).should == 15
      end
    end

    context 'when dealing with an offer from the same partner' do
      before :each do
        @offer = Factory(:app, :partner => @currency.partner).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'calculates publisher amounts' do
        @currency.get_publisher_amount(@offer).should == 0
      end

      it 'calculates advertiser amounts' do
        @currency.get_advertiser_amount(@offer).should == 0
      end

      it 'calculates tapjoy amounts' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end

      it 'calculates reward amounts' do
        @currency.get_reward_amount(@offer).should == 25
      end
    end

    context 'when dealing with any other offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
      end

      it 'calculates publisher amounts' do
        @currency.get_publisher_amount(@offer).should == 12
      end

      it 'calculates advertiser amounts' do
        @currency.get_advertiser_amount(@offer).should == -25
      end

      it 'calculates tapjoy amounts' do
        @currency.get_tapjoy_amount(@offer).should == 13
      end

      it 'calculates reward amounts' do
        @currency.get_reward_amount(@offer).should == 12
      end
    end

    context 'when dealing with a 3-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = Factory(:app)
      end

      it 'calculates publisher amounts' do
        @currency.get_publisher_amount(@offer, @displayer_app).should == 0
      end

      it 'calculates advertiser amounts' do
        @currency.get_advertiser_amount(@offer).should == -25
      end

      it 'calculates tapjoy amounts' do
        @currency.get_tapjoy_amount(@offer, @displayer_app).should == 13
      end

      it 'calculates reward amounts' do
        @currency.get_reward_amount(@offer).should == 12
      end

      it 'calculates displayer amounts' do
        @currency.get_displayer_amount(@offer, @displayer_app).should == 12
      end
    end

    context 'when dealing with a 2-party displayer offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.update_attributes({:payment => 25})
        @displayer_app = @currency.app
      end

      it 'calculates publisher amounts' do
        @currency.get_publisher_amount(@offer, @displayer_app).should == 0
      end

      it 'calculates advertiser amounts' do
        @currency.get_advertiser_amount(@offer).should == -25
      end

      it 'calculates tapjoy amounts' do
        @currency.get_tapjoy_amount(@offer, @displayer_app).should == 13
      end

      it 'calculates reward amounts' do
        @currency.get_reward_amount(@offer).should == 12
      end

      it 'calculates displayer amounts' do
        @currency.get_displayer_amount(@offer, @displayer_app).should == 12
      end
    end

    context 'when dealing with a direct-pay offer' do
      before :each do
        @offer = Factory(:app).primary_offer
        @offer.payment = 100
        @offer.reward_value = 50
        @offer.direct_pay = Offer::DIRECT_PAY_PROVIDERS.first
      end

      it 'calculates publisher amounts' do
        @currency.get_publisher_amount(@offer).should == 100
      end

      it 'calculates advertiser amounts' do
        @currency.get_advertiser_amount(@offer).should == -100
      end

      it 'calculates tapjoy amounts' do
        @currency.get_tapjoy_amount(@offer).should == 0
      end

      it 'calculates reward amounts' do
        @currency.get_reward_amount(@offer).should == 50
      end
    end

    context 'when created' do
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

      context 'when not tapjoy-managed' do
        it 'validates callback url' do
          Resolv.stubs(:getaddress).raises(URI::InvalidURIError)
          @currency.callback_url = 'http://tapjoy' # invalid url
          @currency.save
          @currency.errors.on(:callback_url).should == 'is not a valid url'
        end
      end
    end

  end
end
