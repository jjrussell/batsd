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

  it "rejects depending on countries blacklist" do
    device = Factory(:device)
    @offer.item.countries_blacklist = ["GB"]
    geoip_data = { :country => "US" }
    @offer.send(:geoip_reject?, geoip_data, device).should == false
    geoip_data = { :country => "GB" }
    @offer.send(:geoip_reject?, geoip_data, device).should == true
  end

  it "rejects depending on region" do
    device = Factory(:device)
    @offer.regions = ["CA"]
    geoip_data = { :region => "CA" }
    @offer.send(:geoip_reject?, geoip_data, device).should == false
    geoip_data = { :region => "OR" }
    @offer.send(:geoip_reject?, geoip_data, device).should == true
    @offer.regions = []
    @offer.send(:geoip_reject?, geoip_data, device).should == false
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

  describe '#add_banner_creative' do
    context 'given a valid size' do
      before(:each) do
        @offer.add_banner_creative('320x50')
      end

      it 'adds the banner creative size' do
        @offer.banner_creatives.should include('320x50')
      end

      it 'does not approve the banner' do
        @offer.approved_banner_creatives.should_not include('320x50')
      end
    end

    context 'given an invalid size' do
      before(:each) do
        @offer.add_banner_creative('1x1')
      end

      it 'does not add the banner creative' do
        @offer.banner_creatives.should_not include('1x1')
      end
    end
  end

  describe '#remove_banner_creative' do
    before(:each) do
      @offer.banner_creatives = ['320x50', '640x100']
      @offer.remove_banner_creative('320x50')
    end

    it 'removes the given banner creative' do
      @offer.banner_creatives.should_not include('320x50')
    end

    it 'leaves the other banner creatives' do
      @offer.banner_creatives.should include('640x100')
    end
  end

  describe '#approve_banner_creative' do
    before(:each) do
      @offer.banner_creatives = ['320x50']
    end

    it 'is not approved by default' do
      @offer.approved_banner_creatives.should_not include('320x50')
    end

    context 'given a banner that is not approved' do
      before(:each) do
        @offer.approve_banner_creative('320x50')
      end

      it 'becomes approved' do
        @offer.approved_banner_creatives.should include('320x50')
      end
    end

    context 'given a banner that is not uploaded' do
      before(:each) do
        @offer.approve_banner_creative('640x100')
      end

      it 'does not become approved' do
        @offer.approved_banner_creatives.should_not include('640x100')
      end
    end
  end

  describe '#sync_creative_approval' do
    before(:each) do
      @offer.banner_creatives = ['320x50', '640x100', '768x90']
      @offer.approved_banner_creatives = ['320x50', '1x1']

      @valid_remove   = @offer.add_banner_approval(Factory(:user), '320x50')
      @valid_keep     = @offer.add_banner_approval(Factory(:user), '640x100')
      @invalid_remove = @offer.add_banner_approval(Factory(:user), '2x2')

      @offer.send(:sync_creative_approval)
      @offer.approvals.reload
    end

    it 'removes the approval record for already approved banners' do
      @offer.approvals.should_not include(@valid_remove)
    end

    it 'automatically approves banners with no approval record' do
      @offer.approved_banner_creatives.should include('768x90')
    end

    context 'given a banner that is no longer present' do
      it 'removes the approval record' do
        @offer.approvals.should_not include(@invalid_remove)
      end

      it 'removes the now invalid approval' do
        @offer.approved_banner_creatives.should_not include('1x1')
      end
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

  context "An App Offer for a free app" do
    before :each do
      Offer.any_instance.stubs(:cache) # for some reason the acts_as_cacheable stuff screws up the ability to stub methods as expected
      @offer = Factory(:app).primary_offer.target # need to use the HasOneAssociation's "target" in order for stubbing to work
    end

    context "with banner_creatives" do
      before :each do
        @offer.featured = true
        @offer.banner_creatives = %w(480x320 320x480)
      end

      it "fails if asset data not provided" do
        @offer.save.should be_false
        @offer.errors[:custom_creative_480x320_blob].should == "480x320 custom creative file not provided."
        @offer.errors[:custom_creative_320x480_blob].should == "320x480 custom creative file not provided."
      end

      it "uploads assets to s3 when data is provided" do
        @offer.banner_creative_480x320_blob = "image_data"
        @offer.banner_creative_320x480_blob = "image_data"

        @offer.expects(:upload_banner_creative!).with("image_data", "480x320").returns(nil)
        @offer.expects(:upload_banner_creative!).with("image_data", "320x480").returns(nil)

        @offer.save!
      end

      it "copies s3 assets over when cloned" do
        class S3Object
          def read; return "image_data"; end
        end

        @offer.stubs(:banner_creative_s3_object).with("480x320").returns(S3Object.new)
        @offer.stubs(:banner_creative_s3_object).with("320x480").returns(S3Object.new)

        clone = @offer.clone
        clone.bid = clone.min_bid

        clone.expects(:upload_banner_creative!).with("image_data", "480x320").returns(nil)
        clone.expects(:upload_banner_creative!).with("image_data", "320x480").returns(nil)

        clone.save!
      end
    end
  end
end
