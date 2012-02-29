require 'spec_helper'

describe App do
  # Check associations
  it { should have_many :currencies }
  it { should have_many :non_rewarded_featured_offers }
  it { should have_many :non_rewarded_offers }
  it { should have_many :offers }
  it { should have_many :publisher_conversions }
  it { should have_many :rewarded_featured_offers }
  it { should have_many :app_metadatas }
  it { should have_one :rating_offer }
  it { should have_one :primary_currency }
  it { should have_one :primary_offer }
  it { should have_one :primary_rewarded_featured_offer }
  it { should have_one :primary_non_rewarded_featured_offer }
  it { should have_one :primary_non_rewarded_offer }
  it { should have_one :primary_app_metadata }
  it { should belong_to :partner }

  # Check validations
  it { should validate_presence_of :partner }
  it { should validate_presence_of :name }

  context 'An App' do
    before :each do
      @app = Factory(:app)
    end

    it 'does not list North Korea as a possible appstore country' do
      App::APPSTORE_COUNTRIES_OPTIONS.map(&:last).should_not include('KP')
    end
  end

  describe '#can_have_new_currency?' do
    before :each do
      @app = Factory(:app)
    end

    context 'without currencies' do
      it 'returns true ' do
        @app.should be_can_have_new_currency
      end
    end

    context 'without currency that has special callback' do
      it 'returns true' do
        Factory(:currency, :app_id => @app.id, :callback_url => 'http://foo.com')
        Factory(:currency, :app_id => @app.id, :callback_url => 'http://bar.com')
        @app.should be_can_have_new_currency
      end
    end

    context 'with currency that has special callback' do
      it 'returns false' do
        special_url = Currency::SPECIAL_CALLBACK_URLS.sample
        Factory(:currency, :app_id => @app.id, :callback_url => special_url)
        @app.should_not be_can_have_new_currency
      end
    end
  end

  describe '#test_offer' do
    before :each do
      @app = Factory(:app)
      @test_offer = @app.test_offer
    end

    it 'creates test Offer with the same ID' do
      @test_offer.id.should == @app.id
      @test_offer.item_id.should == @app.id
      @test_offer.item_type.should == 'TestOffer'
    end
  end

  describe '#test_video_offer' do
    before :each do
      @app = Factory(:app)
      @test_video_offer = @app.test_video_offer
      @test_video_offer_primary_offer = @test_video_offer.primary_offer
    end

    it 'creates test VideoOffer with ID "test_video"' do
      @test_video_offer.id.should == 'test_video'
      @test_video_offer.partner_id.should == @app.partner_id
    end

    it 'creates test VideoOffer with primary offer ID "test_video"' do
      @test_video_offer_primary_offer.id.should == 'test_video'
      @test_video_offer_primary_offer.item_id.should == 'test_video'
      @test_video_offer_primary_offer.item_type.should == 'TestVideoOffer'
    end
  end

  context 'with Offers' do
    before :each do
      @app = Factory(:app)
      @offer = @app.primary_offer
    end

    it "updates its offers' bids when its price changes" do
      @app.primary_app_metadata.update_attributes({:price => 400})
      @offer.reload
      @offer.bid.should equal(200)
      @offer.price.should equal(400)
    end

    it "doesn't update offer's device types unless store id changes" do
      @offer.device_types.should == Offer::APPLE_DEVICES.to_json
      @offer.update_attributes({:device_types => Offer::ANDROID_DEVICES})
      @app.primary_app_metadata.update_attributes({:age_rating => 2})
      @offer.reload
      @offer.age_rating.should == 2
      @offer.device_types.should == Offer::ANDROID_DEVICES.to_json
    end

    it "updates offer's device types if store id changes" do
      @offer.device_types.should == Offer::APPLE_DEVICES.to_json
      @offer.update_attributes({:device_types => Offer::ANDROID_DEVICES})
      @offer.device_types.should == Offer::ANDROID_DEVICES.to_json
      @app.update_app_metadata('7654321')
      @app.save!
      @offer.reload
      @offer.device_types.should == Offer::APPLE_DEVICES.to_json
    end
  end

  context 'with Action Offers' do
    before :each do
      @action_offer = Factory(:action_offer)
      @app = @action_offer.app
    end

    it 'updates action offer hidden field' do
      @app.update_attributes({:hidden => true})
      @action_offer.reload
      @action_offer.should be_hidden
      @action_offer.primary_offer.should_not be_tapjoy_enabled
    end

    it "updates action offer bids when its price changes" do
      @app.primary_app_metadata.update_attributes({:price => 400})
      @action_offer.reload
      @action_offer.primary_offer.bid.should equal(200)
      @action_offer.primary_offer.price.should equal(400)
    end

    it 'does not update action offer bids if it has a prerequisite offer' do
      @action_offer.prerequisite_offer = @app.primary_offer
      @action_offer.save
      offer = @action_offer.primary_offer
      @app.primary_app_metadata.update_attributes({:price => 400})
      offer.reload
      offer.bid.should equal(10)
    end
  end

  context 'with a Non-Rewarded Featured Offer' do
    before :each do
      @app = Factory :app
      @new_offer = @app.primary_offer.create_non_rewarded_featured_clone
      @app.reload
    end

    it 'has non-rewarded featured associations' do
      @app.primary_non_rewarded_featured_offer.should == @new_offer
      @app.non_rewarded_featured_offers.size.should equal(1)
      @app.non_rewarded_featured_offers.should include(@new_offer)
    end

    it 'does not have rewarded featured associations' do
      @app.primary_rewarded_featured_offer.should be_nil
      @app.rewarded_featured_offers.should be_empty
    end

    it 'does not have non-rewarded associations' do
      @app.primary_non_rewarded_offer.should be_nil
      @app.non_rewarded_offers.should be_empty
    end
  end

  context 'with a Rewarded Featured Offer' do
    before :each do
      @app = Factory :app
      @new_offer = @app.primary_offer.create_rewarded_featured_clone
      @app.reload
    end

    it 'has rewarded featured associations' do
      @app.primary_rewarded_featured_offer.should == @new_offer
      @app.rewarded_featured_offers.size.should equal(1)
      @app.rewarded_featured_offers.should include(@new_offer)
    end

    it 'does not have non-rewarded featured associations' do
      @app.primary_non_rewarded_featured_offer.should be_nil
      @app.non_rewarded_featured_offers.should be_empty
    end

    it 'does not have non-rewarded associations' do
      @app.primary_non_rewarded_offer.should be_nil
      @app.non_rewarded_offers.should be_empty
    end
  end

  context 'with a Non-Rewarded Offer' do
    before :each do
      @app = Factory :app
      @new_offer = @app.primary_offer.create_non_rewarded_clone
      @app.reload
    end

    it 'has non-rewarded associations' do
      @app.primary_non_rewarded_offer.should == @new_offer
      @app.non_rewarded_offers.size.should equal(1)
      @app.non_rewarded_offers.should include(@new_offer)
    end

    it 'does not have rewarded featured associations' do
      @app.primary_rewarded_featured_offer.should be_nil
      @app.rewarded_featured_offers.should be_empty
    end

    it 'does not have non-rewarded featured associations' do
      @app.primary_non_rewarded_featured_offer.should be_nil
      @app.non_rewarded_featured_offers.should be_empty
    end
  end
end
