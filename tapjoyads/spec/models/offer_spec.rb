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

  it "should update its payment when the bid is changed" do
    @offer.update_attributes({:bid => 500})
    @offer.reload
    @offer.payment.should == 500
  end

  it "should update its payment correctly with respect to premier discounts" do
    @offer.partner.premier_discount = 10
    @offer.update_attributes({:bid => 500})
    @offer.reload
    @offer.payment.should == 450
  end

  it "should not allow bids below min_bid" do
    @offer.bid = @offer.min_bid - 5
    @offer.valid?.should == false
  end

  it "should reject depending on countries blacklist" do
    device = Factory(:device)
    @offer.item.countries_blacklist = ["GB"]
    geoip_data = { :country => "US" }
    @offer.send(:geoip_reject?, geoip_data, device).should == false
    geoip_data = { :country => "GB" }
    @offer.send(:geoip_reject?, geoip_data, device).should == true
  end

  it "should reject depending on region" do
    device = Factory(:device)
    @offer.regions = ["CA"]
    geoip_data = { :region => "CA" }
    @offer.send(:geoip_reject?, geoip_data, device).should == false
    geoip_data = { :region => "OR" }
    @offer.send(:geoip_reject?, geoip_data, device).should == true
    @offer.regions = []
    @offer.send(:geoip_reject?, geoip_data, device).should == false
  end

  it "should return proper linkshare account url" do
    url = 'http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=TEST&mt=8'
    linkshare_url = Linkshare.add_params(url)
    linkshare_url.should == "#{url}&partnerId=30&siteID=OxXMC6MRBt4"

    linkshare_url = Linkshare.add_params(url, 'tradedoubler')
    linkshare_url.should == "#{url}&partnerId=2003&tduid=UK1800811"
  end

  it "should reject based on source" do
    @offer.approved_sources = ['tj_games']
    @offer.send(:source_reject?, 'offerwall').should be_true
    @offer.send(:source_reject?, 'tj_games').should be_false
  end

  it "should not reject on source when approved_sources is empty" do
    @offer.send(:source_reject?, 'foo').should be_false
    @offer.send(:source_reject?, 'offerwall').should be_false
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
end
