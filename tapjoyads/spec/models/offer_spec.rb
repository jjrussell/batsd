require 'spec_helper'

describe Offer do

  it { should have_many :advertiser_conversions }
  it { should have_many :rank_boosts }
  it { should belong_to :partner }
  it { should belong_to :item }

  it { should validate_presence_of :partner }
  it { should validate_presence_of :item }
  it { should validate_presence_of :name }
  it { should validate_presence_of :url }

  it { should validate_numericality_of :price }
  it { should validate_numericality_of :bid }
  it { should validate_numericality_of :daily_budget }
  it { should validate_numericality_of :overall_budget }
  it { should validate_numericality_of :conversion_rate }
  it { should validate_numericality_of :min_conversion_rate }
  it { should validate_numericality_of :show_rate }
  it { should validate_numericality_of :payment_range_low }
  it { should validate_numericality_of :payment_range_high }

  before :each do
    fake_the_web
    @app = Factory :app
    @offer = @app.primary_offer
  end

  it "updates its payment when the bid is changed" do
    @offer.update_attributes({:bid => 500})
    @offer.reload
    @offer.payment.should == 500
  end

  it "updates its payment correctly with respect to premier discounts" do
    @offer.partner.premier_discount = 10
    @offer.update_attributes({:bid => 500})
    @offer.reload
    @offer.payment.should == 450
  end

  it "doesn't allow bids below min_bid" do
    @offer.bid = @offer.min_bid - 5
    @offer.valid?.should == false
  end

  it "rejects depending on mobile country codes" do
    @offer.countries = ["GB"]
    geoip_data = { :country => "US" }
    mobile_country_code = "310"
    @offer.send(:geoip_reject?, geoip_data, mobile_country_code).should == true
    geoip_data = { :country => "GB" }
    mobile_country_code = "234"
    @offer.send(:geoip_reject?, geoip_data, mobile_country_code).should == false
  end

  it "rejects depending on countries" do
    @offer.countries = ["GB"]
    geoip_data = { :country => "US" }
    @offer.send(:geoip_reject?, geoip_data).should == true
    geoip_data = { :country => "GB" }
    @offer.send(:geoip_reject?, geoip_data).should == false
  end

  it "rejects depending on countries blacklist" do
    @offer.item.countries_blacklist = ["GB"]
    geoip_data = { :country => "US" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :country => "GB" }
    @offer.send(:geoip_reject?, geoip_data).should == true
  end

  it "rejects depending on region" do
    @offer.regions = ["CA"]
    geoip_data = { :region => "CA" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :region => "OR" }
    @offer.send(:geoip_reject?, geoip_data).should == true
    @offer.regions = []
    @offer.send(:geoip_reject?, geoip_data).should == false
  end

  it "returns proper linkshare account url" do
    url = 'http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=TEST&mt=8'
    linkshare_url = Linkshare.add_params(url)
    linkshare_url.should == "#{url}&partnerId=30&siteID=OxXMC6MRBt4"

    linkshare_url = Linkshare.add_params(url, 'tradedoubler')
    linkshare_url.should == "#{url}&partnerId=2003&tduid=UK1800811"
  end

  it "rejects based on source" do
    @offer.approved_sources = ['tj_games']
    @offer.send(:source_reject?, 'offerwall').should be_true
    @offer.send(:source_reject?, 'tj_games').should be_false
  end

  it "doesn't reject on source when approved_sources is empty" do
    @offer.send(:source_reject?, 'foo').should be_false
    @offer.send(:source_reject?, 'offerwall').should be_false
  end

  context "with min_bid_override set" do
    before :each do
      @offer.min_bid_override = 1234
    end

    it "has a min_bid same as min_bid_override" do
      @offer.min_bid.should == 1234
    end
  end

  context "without min_bid_override set" do
    before :each do
      @offer.min_bid_override = nil
    end

    it "has a min_bid same as calculated_min_bid" do
      @offer.min_bid.should == @offer.send(:calculated_min_bid)
    end
  end

  context "with a paid app item" do
    before :each do
      @app = Factory(:app, :price => 150)
      @offer = @app.primary_offer
    end

    context "when featured and rewarded" do
      before :each do
        @offer.featured = true
        @offer.rewarded = true
      end

      it "has a min_bid of 150" do
        @offer.min_bid.should == 150
      end
    end

    context "when non-rewarded" do
      before :each do
        @offer.rewarded = false
      end

      it "has a min_bid of 100" do
        @offer.min_bid.should == 100
      end
    end

    context "when not featured and rewarded" do
      before :each do
        @offer.featured = false
        @offer.rewarded = true
      end

      it "has a min_bid of 75" do
        @offer.min_bid.should == 75
      end
    end
  end

  context "with a free app item" do
    before :each do
      @app = Factory(:app, :price => 0)
      @offer = @app.primary_offer
    end

    context "when featured and rewarded" do
      before :each do
        @offer.featured = true
        @offer.rewarded = true
      end

      it "has a min_bid of 65" do
        @offer.min_bid.should == 65
      end
    end

    context "when non-rewarded" do
      before :each do
        @offer.rewarded = false
      end

      it "has a min_bid of 100" do
        @offer.min_bid.should == 100
      end
    end

    context "when not featured and rewarded" do
      before :each do
        @offer.featured = false
        @offer.rewarded = true
      end

      it "has a min_bid of 10" do
        @offer.min_bid.should == 10
      end
    end
  end

  context "with a video item" do
    before :each do
      @video = Factory(:video_offer)
      @offer = @video.primary_offer
    end

    it "has a min_bid of 15" do
      @offer.min_bid.should == 15
    end
  end

  context "with an action offer item" do
    before :each do
      @action = Factory(:action_offer)
      @offer = @action.primary_offer
    end

    context "on Windows" do
      before :each do
        @offer.device_types = %w( windows ).to_json
      end

      it "has a min_bid of 25" do
        @offer.min_bid.should == 25
      end
    end

    context "on Android" do
      before :each do
        @offer.device_types = %w( android ).to_json
      end

      it "has a min_bid of 25" do
        @offer.min_bid.should == 25
      end
    end

    context "on iOS" do
      before :each do
        @offer.device_types = %w( iphone ).to_json
      end

      it "has a min_bid of 35" do
        @offer.min_bid.should == 35
      end
    end
  end

  context "with a generic offer item" do
    before :each do
      @generic = Factory(:generic_offer)
      @offer = @generic.primary_offer
    end

    it "has a min_bid of 0" do
      @offer.min_bid.should == 0
    end
  end

  describe "#create_clone" do
    context "when no options are specified" do
      before :each do
        @new_offer = @offer.send :create_clone
      end

      it "creates an offer with the same featured status" do
        @new_offer.should_not be_featured
      end

      it "creates an offer with the same rewarded status" do
        @new_offer.should be_rewarded
      end

      it "doesn't replace the app's primary offer" do
        @app.primary_offer.should_not be @new_offer
      end

      it "adds the new offer to the app's offers list" do
        @app.offers.should include @new_offer
      end
    end

    context "when 'rewarded' is false" do
      before :each do
        @new_offer = @offer.send(:create_clone, { :rewarded => false })
      end

      it "creates an offer that is non-rewarded" do
        @new_offer.should_not be_rewarded
      end

      it "creates an offer that is not featured" do
        @new_offer.should_not be_featured
      end

      it "adds the new offer to the app's offers list" do
        @app.offers.should include @new_offer
      end

      it "sets the new offer as the app's primary non-rewarded offer" do
        @app.primary_non_rewarded_offer.should == @new_offer
      end

      it "adds the new offer to the app's non-rewarded offers list" do
        @app.non_rewarded_offers.should include @new_offer
      end
    end

    context "when 'rewarded' is false and 'featured' is true" do
      before :each do
        @new_offer = @offer.send(:create_clone, { :rewarded => false, :featured => true })
      end

      it "creates an offer that is non-rewarded" do
        @new_offer.should_not be_rewarded
      end

      it "creates an offer that is featured" do
        @new_offer.should be_featured
      end

      it "adds the new offer ot the app's offers list" do
        @app.offers.should include @new_offer
      end

      it "sets the new offer as the app's primary non-rewarded featured offer" do
        @app.primary_non_rewarded_featured_offer.should == @new_offer
      end

      it "adds the new offer to the app's non-rewarded featured offers list" do
        @app.non_rewarded_featured_offers.should include @new_offer
      end
    end

    context "when 'rewarded' is true and 'featured' is true" do
      before :each do
        @new_offer = @offer.send(:create_clone, { :rewarded => true, :featured => true })
      end

      it "creates an offer that is rewarded" do
        @new_offer.should be_rewarded
      end

      it "creates an offer that is featured" do
        @new_offer.should be_featured
      end

      it "adds the new offer ot the app's offers list" do
        @app.offers.should include @new_offer
      end

      it "sets the new offer as the app's primary rewarded featured offer" do
        @app.primary_rewarded_featured_offer.should == @new_offer
      end

      it "adds the new offer to the app's rewarded featured offers list" do
        @app.rewarded_featured_offers.should include @new_offer
      end
    end
  end

  describe "#create_non_rewarded_clone" do
    before :each do
      @new_offer = @offer.create_non_rewarded_clone
    end

    it "creates an offer that is non-rewarded" do
      @new_offer.should_not be_rewarded
    end

    it "creates an offer that is not featured" do
      @new_offer.should_not be_featured
    end

    it "adds the new offer to the app's offers list" do
      @app.offers.should include @new_offer
    end

    it "sets the new offer as the app's primary non-rewarded offer" do
      @app.primary_non_rewarded_offer.should == @new_offer
    end

    it "adds the new offer to the app's non-rewarded offers list" do
      @app.non_rewarded_offers.should include @new_offer
    end
  end

  describe "#create_non_rewarded_featured_clone" do
    before :each do
      @new_offer = @offer.create_non_rewarded_featured_clone
    end

    it "creates an offer that is non-rewarded" do
      @new_offer.should_not be_rewarded
    end

    it "creates an offer that is featured" do
      @new_offer.should be_featured
    end

    it "adds the new offer ot the app's offers list" do
      @app.offers.should include @new_offer
    end

    it "sets the new offer as the app's primary non-rewarded featured offer" do
      @app.primary_non_rewarded_featured_offer.should == @new_offer
    end

    it "adds the new offer to the app's non-rewarded featured offers list" do
      @app.non_rewarded_featured_offers.should include @new_offer
    end
  end

  describe "#create_rewarded_featured_clone" do
    before :each do
      @new_offer = @offer.create_rewarded_featured_clone
    end

    it "creates an offer that is rewarded" do
      @new_offer.should be_rewarded
    end

    it "creates an offer that is featured" do
      @new_offer.should be_featured
    end

    it "adds the new offer ot the app's offers list" do
      @app.offers.should include @new_offer
    end

    it "sets the new offer as the app's primary rewarded featured offer" do
      @app.primary_rewarded_featured_offer.should == @new_offer
    end

    it "adds the new offer to the app's rewarded featured offers list" do
      @app.rewarded_featured_offers.should include @new_offer
    end
  end

  describe '#valid?' do
    context "when SDK-less is enabled" do
      before :each do
        @offer.device_types = %w( android ).to_json
        @offer.item_type = 'App'
        @offer.sdkless = true
      end

      it "allows Android-only offers" do
        @offer.should be_valid
      end

      it "allows app offers" do
        @offer.should be_valid
      end

      it "disallows non-Android offers" do
        @offer.device_types = %w( iphone ipad itouch ).to_json
        @offer.should_not be_valid
      end

      it "disallows multi-platform offers" do
        @offer.device_types = %w( android iphone ipad itouch ).to_json
        @offer.should_not be_valid
      end

      it "disallows non-app offers" do
        @offer.item_type = 'GenericOffer'
        @offer.should_not be_valid
      end

      it "disallows pay-per-click offers" do
        @offer.pay_per_click = true
        @offer.should_not be_valid
      end
    end
  end
end
