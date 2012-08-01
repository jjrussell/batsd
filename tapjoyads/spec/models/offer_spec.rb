# encoding: UTF-8

require 'spec_helper'

describe Offer do

  it { should have_many :advertiser_conversions }
  it { should have_many :rank_boosts }
  it { should have_many :sales_reps }
  it { should belong_to :partner }
  it { should belong_to :item }
  it { should belong_to :prerequisite_offer }

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
    @app = FactoryGirl.create :app
    @offer = @app.primary_offer
  end

  it "updates its payment when the bid is changed" do
    @offer.update_attributes({:bid => 500})
    @offer.reload
    @offer.payment.should == 500
  end

  describe "applies discounts correctly" do
    context "to_json an app offer item" do
      before :each do
        Offer.any_instance.stub(:app_offer?).and_return true
        @offer.partner.premier_discount = 10
      end

      context "with a partner who has the discount_all_offer_types flag set" do
        it "applies the partner discount to the offer" do
          @offer.partner.discount_all_offer_types = true
          @offer.update_attributes({:bid => 500})
          @offer.reload
          @offer.payment.should == 450
        end
      end
      context "with a partner who does not have the discount_all_offer_types flag set" do
        it "applies the partner discount to the offer" do
          @offer.partner.discount_all_offer_types = false
          @offer.update_attributes({:bid => 500})
          @offer.reload
          @offer.payment.should == 450
        end
      end
    end

    context "to a non app offer item" do
      before :each do
        Offer.any_instance.stub(:app_offer?).and_return false
        @offer.partner.premier_discount = 10
      end

      context "with a partner who has the discount_all_offer_types flag set" do
        it "applies the partner discount to the offer" do
          @offer.partner.discount_all_offer_types = true
          @offer.update_attributes({:bid => 500})
          @offer.reload
          @offer.payment.should == 450
        end
      end
      context "with a partner who does not have the discount_all_offer_types flag set" do
        it "does not apply the partner discount to the offer" do
          @offer.partner.discount_all_offer_types = false
          @offer.update_attributes({:bid => 500})
          @offer.reload
          @offer.payment.should == 500
        end
      end
    end
  end

  it "enforces a minimum payment of one cent if the bid is greater than zero" do
    @offer.partner.premier_discount = 100
    @offer.update_attributes({:bid => 500})
    @offer.reload
    @offer.payment.should == 1
  end

  it "doesn't allow bids below min_bid" do
    @offer.bid = @offer.min_bid - 5
    @offer.should_not be_valid
  end

  it "rejects depending on prerequisites" do
    device = Factory(:device)
    app = FactoryGirl.create :app
    prerequisite_offer = app.primary_offer
    @offer.send(:prerequisites_not_complete?, device).should == false
    @offer.update_attributes({ :prerequisite_offer_id => prerequisite_offer.id })
    @offer.send(:prerequisites_not_complete?, device).should == true
    device.set_last_run_time(app.id)
    @offer.send(:prerequisites_not_complete?, device).should == false

    exclusion_offer1 = (FactoryGirl.create :action_offer).primary_offer
    exclusion_offer2 = (FactoryGirl.create :generic_offer).primary_offer
    exclusion_offer3 = (FactoryGirl.create :video_offer).primary_offer
    @offer.exclusion_prerequisite_offer_ids = "[\"#{exclusion_offer1.id}\", \"#{exclusion_offer2.id}\", \"#{exclusion_offer3}\"]"
    @offer.get_exclusion_prerequisite_offer_ids
    @offer.send(:prerequisites_not_complete?, device).should == false
    device.set_last_run_time(exclusion_offer1.item_id)
    @offer.send(:prerequisites_not_complete?, device).should == true
    device.set_last_run_time(exclusion_offer2.item_id)
    @offer.send(:prerequisites_not_complete?, device).should == true
    device.set_last_run_time(exclusion_offer3.item_id)
    @offer.send(:prerequisites_not_complete?, device).should == true
  end

  it "rejects depending on primary country" do
    geoip_data = { :primary_country => nil }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :primary_country => "GB" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :primary_country => "US" }
    @offer.send(:geoip_reject?, geoip_data).should == false

    @offer.countries = ["GB"].to_json
    @offer.get_countries
    geoip_data = { :primary_country => nil }
    @offer.send(:geoip_reject?, geoip_data).should == true
    geoip_data = { :primary_country => "GB" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :primary_country => "US" }
    @offer.send(:geoip_reject?, geoip_data).should == true
  end

  it "rejects depending on countries blacklist" do
    geoip_data = { :primary_country => nil }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :primary_country => "GB" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :primary_country => "US" }
    @offer.send(:geoip_reject?, geoip_data).should == false

    @offer.item.primary_app_metadata.countries_blacklist = ["GB"].to_json
    @offer.countries_blacklist(true)
    geoip_data = { :primary_country => nil }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :primary_country => "GB" }
    @offer.send(:geoip_reject?, geoip_data).should == true
    geoip_data = { :primary_country => "US" }
    @offer.send(:geoip_reject?, geoip_data).should == false
  end

  it "rejects depending on region" do
    geoip_data = { :region => nil }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :region => "CA" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :region => "OR" }
    @offer.send(:geoip_reject?, geoip_data).should == false

    @offer.regions = ["CA"].to_json
    @offer.get_regions
    geoip_data = { :region => nil }
    @offer.send(:geoip_reject?, geoip_data).should == true
    geoip_data = { :region => "CA" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :region => "OR" }
    @offer.send(:geoip_reject?, geoip_data).should == true
  end

  it "rejects depending on dma codes" do
    geoip_data = { :dma_code => nil }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :dma_code => "123" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :dma_code => "234" }
    @offer.send(:geoip_reject?, geoip_data).should == false

    @offer.dma_codes = ["123"].to_json
    @offer.get_dma_codes
    geoip_data = { :dma_code => nil }
    @offer.send(:geoip_reject?, geoip_data).should == true
    geoip_data = { :dma_code => "123" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :dma_code => "234" }
    @offer.send(:geoip_reject?, geoip_data).should == true
  end

  it "rejects depending on cities" do
    geoip_data = { :city => nil }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :city => "San Francisco" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :city => "Tokyo" }
    @offer.send(:geoip_reject?, geoip_data).should == false

    @offer.cities = ["San Francisco"].to_json
    @offer.get_cities
    geoip_data = { :city => nil }
    @offer.send(:geoip_reject?, geoip_data).should == true
    geoip_data = { :city => "San Francisco" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :city => "Tokyo" }
    @offer.send(:geoip_reject?, geoip_data).should == true
  end

  it "rejects depending on carriers" do
    @offer.carriers = ["Verizon", "NTT DoCoMo"].to_json
    mobile_carrier_code = '440.01'
    @offer.send(:carriers_reject?, mobile_carrier_code).should == false
    mobile_carrier_code = '123.123'
    @offer.send(:carriers_reject?, mobile_carrier_code).should == true
    @offer.send(:carriers_reject?, nil).should == true
    @offer.update_attributes({ :carriers => '[]' })
    @offer.reload
    @offer.send(:carriers_reject?, mobile_carrier_code).should == false
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

  it "rejects SDK-less offers when SDK version is older than 8.2.0" do
    @offer.sdkless = true
    @offer.send(:sdkless_reject?, '8.1.0').should be_true
  end

  it "accepts non-SDK-less offers when SDK version is older than 8.2.0" do
    @offer.sdkless = false
    @offer.send(:sdkless_reject?, '8.1.0').should be_false
  end

  it "doesn't reject SDK-less when SDK version is at least 8.2.0" do
    @offer.sdkless = true
    @offer.send(:sdkless_reject?, '8.2.0').should be_false
  end

  it "doesn't reject on source when approved_sources is empty" do
    @offer.send(:source_reject?, 'foo').should be_false
    @offer.send(:source_reject?, 'offerwall').should be_false
  end

  it 'rejects rewarded offers that are close to zero' do
    currency = FactoryGirl.create(:currency, {:conversion_rate => 1})
    @offer.send(:miniscule_reward_reject?, currency).should be_true
  end

  it "doesn't reject rewarded offers that are close to 1" do
    currency = FactoryGirl.create(:currency, {:conversion_rate => 18})
    @offer.send(:miniscule_reward_reject?, currency).should be_false
  end

  it "excludes the appropriate columns for the for_offer_list scope" do
    offer = Offer.for_offer_list.find(@offer.id)
    fetched_cols = offer.attribute_names & Offer.column_names

    (fetched_cols & Offer::OFFER_LIST_EXCLUDED_COLUMNS).should == []
    fetched_cols.sort.should == [ 'id', 'item_id', 'item_type', 'partner_id',
                                  'name', 'url', 'price', 'bid', 'payment',
                                  'conversion_rate', 'show_rate', 'self_promote_only',
                                  'device_types', 'countries',
                                  'age_rating', 'multi_complete', 'featured',
                                  'publisher_app_whitelist', 'direct_pay', 'reward_value',
                                  'third_party_data', 'payment_range_low',
                                  'payment_range_high', 'icon_id_override', 'rank_boost',
                                  'normal_bid', 'normal_conversion_rate', 'normal_avg_revenue',
                                  'normal_price', 'over_threshold', 'rewarded', 'reseller_id',
                                  'cookie_tracking', 'min_os_version', 'screen_layout_sizes',
                                  'interval', 'banner_creatives', 'dma_codes', 'regions',
                                  'wifi_only', 'approved_sources', 'approved_banner_creatives',
                                  'sdkless', 'carriers', 'cities', 'impression_tracking_urls',
                                  'click_tracking_urls', 'conversion_tracking_urls', 'creatives_dict',
                                  'prerequisite_offer_id', 'exclusion_prerequisite_offer_ids',
                                ].sort
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
      @app = FactoryGirl.create(:app)
      @app.primary_app_metadata.update_attributes({:price => 150})
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
      @app = FactoryGirl.create(:app)
      @app.primary_app_metadata.update_attributes({:price => 0})
      @offer = @app.primary_offer
    end

    context "when featured and rewarded" do
      before :each do
        @offer.featured = true
        @offer.rewarded = true
      end

      it "has a min_bid of 10" do
        @offer.min_bid.should == 10
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
      @video = FactoryGirl.create(:video_offer)
      @offer = @video.primary_offer
    end

    it "has a min_bid of 2" do
      @offer.min_bid.should == 2
    end
  end

  context "with an action offer item" do
    before :each do
      @action = FactoryGirl.create(:action_offer)
      @offer = @action.primary_offer
    end

    context "on Windows" do
      before :each do
        @offer.device_types = %w( windows ).to_json
      end

      it "has a min_bid of 10" do
        @offer.min_bid.should == 10
      end
    end

    context "on Android" do
      before :each do
        @offer.device_types = %w( android ).to_json
      end

      it "has a min_bid of 10" do
        @offer.min_bid.should == 10
      end
    end

    context "on iOS" do
      before :each do
        @offer.device_types = %w( iphone ).to_json
      end

      it "has a min_bid of 10" do
        @offer.min_bid.should == 10
      end
    end
  end

  context "with a generic offer item" do
    before :each do
      @generic = FactoryGirl.create(:generic_offer)
      @offer = @generic.primary_offer
    end

    it "has a min_bid of 0" do
      @offer.min_bid.should == 0
    end

    describe "url generation" do
      describe '#complete_action_url' do
        it "should substitute tokens in the URL" do
          @offer.url = 'https://example.com/complete/TAPJOY_GENERIC?source=TAPJOY_GENERIC_SOURCE&uid=TAPJOY_EXTERNAL_UID'
          source = @offer.source_token('12345')
          uid = Device.advertiser_device_id('x', @offer.partner_id)
          options = {:click_key => 'abcdefg', :udid => 'x', :publisher_app_id => '12345', :currency => 'zxy'}
          @offer.complete_action_url(options).should == "https://example.com/complete/abcdefg?source=#{source}&uid=#{uid}"
        end
      end
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
        @offer.add_banner_creative('image_data', '320x50')
      end

      it 'adds the banner creative size' do
        @offer.banner_creatives.should include('320x50')
      end

      it 'does not approve the banner' do
        @offer.approved_banner_creatives.should_not include('320x50')
      end

      it 'adds the banner creative URL' do
        @offer.creatives_dict.should include('320x50')
      end
    end

    context 'given an invalid size' do
      before(:each) do
        @offer.add_banner_creative('image_data', '1x1')
      end

      it 'does not add the banner creative' do
        @offer.banner_creatives.should_not include('1x1')
      end

      it 'does not add the banner creative URL' do
        @offer.creatives_dict.should_not include('1x1')
      end
    end
  end

  describe '#banner_creative_path' do
    context 'given size populated in creatives_dict' do
      before(:each) do
        @offer.banner_creatives = ['320x50']
        @offer.creatives_dict = {'320x50' => 'test_path'}
      end

      it 'should return the stored path in creatives_dict' do
        @offer.banner_creative_path('320x50', 'jpeg').should == 'banner_creatives/test_path.jpeg'
      end
    end
    context 'given size populated only in banner_creatives' do
      before(:each) do
        @offer.banner_creatives = ['320x50']
        @offer.creatives_dict = {}
        @offer.id = 'test_id'
      end

      it 'should return the statically generated path from hashed_icon_id' do

        @offer.id.should == 'test_id'
        @offer.banner_creative_path('320x50', 'jpeg').should == 'banner_creatives/c068de1ea2c424641fbab45932b4244ab1793651be22a6a5bc0aff5dc4f9ade4_320x50.jpeg'
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

      @valid_remove   = @offer.add_banner_approval(FactoryGirl.create(:user), '320x50')
      @valid_keep     = @offer.add_banner_approval(FactoryGirl.create(:user), '640x100')
      @invalid_remove = @offer.add_banner_approval(FactoryGirl.create(:user), '2x2')

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
    context 'with store_id missing' do
      context 'when tapjoy-enabling' do
        it 'is false' do
          Offer.any_instance.stub(:missing_app_store_id?).and_return(true)
          @offer.tapjoy_enabled = true
          @offer.should_not be_valid
          @offer.errors[:tapjoy_enabled].join.should =~ /store id/i
        end

        it 'can be made true with store_id' do
          Offer.any_instance.stub(:missing_app_store_id?).and_return(false)
          @offer.should be_valid
        end
      end

      context 'when already tapjoy-enabled' do
        it 'is true' do
          @offer.tapjoy_enabled = true
          @offer.save!
          Offer.any_instance.stub(:missing_app_store_id?).and_return(true)
          @offer.should be_valid
        end
      end

      context 'when not tapjoy-enabling' do
        it 'is true' do
          Offer.any_instance.stub(:missing_app_store_id?).and_return(true)
          @offer.should be_valid
        end
      end
    end


    context "when SDK-less is enabled" do
      before :each do
        @offer.device_types = %w( android ).to_json
        @offer.item_type = 'App'
        @offer.sdkless = true
      end

      it "allows Android-only offers" do
        @offer.should be_valid
      end

      it "allows iOS-only offers" do
         @offer.device_types = %w( iphone ipad itouch ).to_json
         @offer.should be_valid
      end

      it "allows app offers" do
        @offer.should be_valid
      end

      it "disallows offers that are not Android or iOS" do
        @offer.device_types = %w( windows ).to_json
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

  describe '#missing_app_store_id?' do
    context 'with non app-related item' do
      it 'is false' do
        @offer.stub(:app_offer?).and_return(false)
        @offer.should_not be_missing_app_store_id
      end
    end

    context 'with App item' do
      context 'and overridden url' do
        it 'is false' do
          @offer.stub(:url_overridden).and_return(true)
          @offer.should_not be_missing_app_store_id
        end
      end

      context 'and url not overridden' do
        context 'with App with store_id' do
          it 'is false' do
            @offer.item.stub(:store_id).and_return('foo')
            @offer.should_not be_missing_app_store_id
          end
        end

        context 'with App with missing store_id' do
          it 'is true' do
            @offer.item.stub(:store_id).and_return(nil)
            @offer.should be_missing_app_store_id
          end
        end
      end
    end
  end

  context "An App Offer for a free app" do
    before :each do
      Offer.any_instance.stub(:cache) # for some reason the acts_as_cacheable stuff screws up the ability to stub methods as expected
      @offer = FactoryGirl.create(:app).primary_offer.target # need to use the HasOneAssociation's "target" in order for stubbing to work
    end

    context "with banner_creatives" do
      before :each do
        @offer.featured = true
        @offer.banner_creatives = %w(480x320 320x480)
      end

      it "fails if asset data not provided" do
        @offer.save.should be_false
        @offer.errors[:custom_creative_480x320_blob].join.should == "480x320 custom creative file not provided."
        @offer.errors[:custom_creative_320x480_blob].join.should == "320x480 custom creative file not provided."
      end

      it "uploads assets to s3 when data is provided" do
        @offer.banner_creative_480x320_blob = "image_data"
        @offer.banner_creative_320x480_blob = "image_data"

        @offer.should_receive(:upload_banner_creative!).with("image_data", "480x320").and_return(nil)
        @offer.should_receive(:upload_banner_creative!).with("image_data", "320x480").and_return(nil)

        @offer.save!
      end

      it "copies s3 assets over when cloned" do
        class S3Object
          def read; return "image_data"; end
        end

        @offer.stub(:banner_creative_s3_object).with("480x320").and_return(S3Object.new)
        @offer.stub(:banner_creative_s3_object).with("320x480").and_return(S3Object.new)

        @offer.should_receive(:upload_banner_creative!).with("image_data", "480x320").and_return(nil)
        @offer.should_receive(:upload_banner_creative!).with("image_data", "320x480").and_return(nil)

        clone = @offer.clone
        clone.bid = clone.min_bid

        clone.save!
      end
    end
  end

  describe '#calculate_target_installs' do
    before :each do
      @offer.daily_budget = 0
      @offer.allow_negative_balance = false
      @offer.partner.balance = 1_000_00
      @num_installs_today = 1
    end

    context 'when negative balance is allowed' do
      before :each do
        @offer.allow_negative_balance = true
      end

      it 'should be infinity' do
        target = @offer.calculate_target_installs(@num_installs_today)
        target.should_not be_finite
      end

      it 'should be limited by daily budget' do
        @offer.daily_budget = 100
        expected = @offer.daily_budget - @num_installs_today
        target = @offer.calculate_target_installs(@num_installs_today)
        target.should == expected
      end
    end

    context 'when negative balance is not allowed' do
      it 'should be based on the balance' do
        expected = @offer.partner.balance / @offer.bid
        target = @offer.calculate_target_installs(@num_installs_today)
        target.should == expected
      end

      it 'should be limited by daily budget' do
        @offer.daily_budget = 100
        expected = @offer.daily_budget - @num_installs_today
        target = @offer.calculate_target_installs(@num_installs_today)
        target.should == expected
      end

      context 'when self-promote only' do
        before :each do
          @offer.self_promote_only = true
        end

        it 'should be infinity' do
          target = @offer.calculate_target_installs(@num_installs_today)
          target.should_not be_finite
        end

        it 'should be limited by daily budget' do
          @offer.daily_budget = 100
          expected = @offer.daily_budget - @num_installs_today
          target = @offer.calculate_target_installs(@num_installs_today)
          target.should == expected
        end
      end
    end

    context 'low budget with negative balance' do
      before :each do
        @offer.partner.balance = 50_00
      end

      it 'should be based on half of balance' do
        expected = @offer.partner.balance / @offer.bid / 2
        target = @offer.calculate_target_installs(@num_installs_today)
        target.should == expected
      end

      it 'should ignore if paid offer' do
        @offer.price = 100
        expected = @offer.partner.balance / @offer.bid
        target = @offer.calculate_target_installs(@num_installs_today)
        target.should == expected
      end
    end
  end

  describe ".for_display_ads" do

    before :each do
      @offer.update_attributes(:conversion_rate => 0.5)
    end

    it "likes some things" do
      Offer.for_display_ads.should include(@offer)
    end

    it "requires zero price" do
      @offer.update_attributes(:price => 5)
      Offer.for_display_ads.should_not include(@offer)
    end

    it "requires a minimal conversion rate" do
      @offer.update_attributes(:conversion_rate => 0.1)
      Offer.for_display_ads.should_not include(@offer)
    end

    it "requires a short name" do
      @offer.update_attributes(:name => 'Thirty-one characters xxxxxxxxx')
      Offer.for_display_ads.should_not include(@offer)
    end

    it "is undaunted by multibyte names" do
      @offer.update_attributes(:name => '在这儿IM 人脉既是财富')
      Offer.for_display_ads.should include(@offer)
    end

    it "still doesn't like long multibyte names" do
      @offer.update_attributes(:name => '在这儿IM 人脉既是财富 在这儿IM 人脉既是财富在这儿IM 人脉既是财富 在这儿IM 人脉既是财富')
      Offer.for_display_ads.should_not include(@offer)
    end

    it "stops complaining about name length if the creatives are approved" do
      @offer.update_attributes({:name => 'Long name xxxxxxxxxxxxxxxxxx', :approved_banner_creatives => ['320x50']})
      Offer.for_display_ads.should include(@offer)
    end
  end

  context "third_party_tracking_url methods" do
    describe 'impression_tracking_urls' do
      it "should trim and remove dups" do
        @offer.impression_tracking_urls = ['https://dummyurl.com?ts=[timestamp]', '  https://dummyurl.com?ts=[timestamp]  ']
        @offer.impression_tracking_urls.should == ['https://dummyurl.com?ts=[timestamp]']
      end
    end

    describe 'click_tracking_urls' do
      it "should trim and remove dups" do
        @offer.click_tracking_urls = ['https://dummyurl.com?ts=[timestamp]', '  https://dummyurl.com?ts=[timestamp]  ']
        @offer.click_tracking_urls.should == ['https://dummyurl.com?ts=[timestamp]']
      end
    end

    describe 'conversion_tracking_urls' do
      it "should trim and remove dups" do
        @offer.conversion_tracking_urls = ['https://dummyurl.com?ts=[timestamp]', '  https://dummyurl.com?ts=[timestamp]  ']
        @offer.conversion_tracking_urls.should == ['https://dummyurl.com?ts=[timestamp]']
      end
    end
  end

  context "queue_third_party_tracking_request methods" do
    before(:each) do
      @urls = ['https://dummyurl.com?ts=[timestamp]', 'https://example.com?ts=[timestamp]&ip=[ip_address]&uid=[uid]&ua=[user_agent]']
      now = Time.zone.now
      Timecop.freeze(now)

      @offer.impression_tracking_urls = @urls
      @offer.click_tracking_urls = @urls
      @offer.conversion_tracking_urls = @urls
    end

    after(:each) do
      Timecop.return
    end

    context "without provided values" do
      before :each do
        now = Time.zone.now
        uid = Click.hashed_key(@offer.format_as_click_key({}))
        user_agent = @offer.source_token(nil)

        @urls.each do |url|
          uid = Device.advertiser_device_id(nil, @offer.partner_id)
          result = url.sub('[timestamp]', "#{now.to_i}.#{now.usec}").sub('[ip_address]', '').sub('[uid]', uid)
          result.sub!('[user_agent]', user_agent)
          Downloader.should_receive(:queue_get_with_retry).with(result).once
        end
      end

      describe ".queue_impression_tracking_requests" do
        it "should queue up the proper GET requests" do
          @offer.queue_impression_tracking_requests
        end
      end

      describe ".queue_click_tracking_requests" do
        it "should queue up the proper GET requests" do
          @offer.queue_click_tracking_requests
        end
      end

      describe ".queue_conversion_tracking_requests" do
        it "should queue up the proper GET requests" do
          @offer.queue_conversion_tracking_requests
        end
      end
    end

    context "with provided values" do
      before :each do
        @ts = 1.hour.from_now
        @ip_address = '127.0.0.1'
        @udid = 'udid'
        uid = Click.hashed_key(@offer.format_as_click_key(:udid => @udid))
        @publisher_app_id = 'pub_app_id'
        user_agent = @offer.source_token(@publisher_app_id)

        @urls.each do |url|
          uid = Device.advertiser_device_id(@udid, @offer.partner_id)
          result = url.sub('[timestamp]', @ts.to_i.to_s).sub('[ip_address]', @ip_address).sub('[uid]', uid)
          result.sub!('[user_agent]', user_agent)
          Downloader.should_receive(:queue_get_with_retry).with(result).once
        end
      end

      describe ".queue_impression_tracking_requests" do
        it "should queue up the proper GET requests" do
          @offer.queue_impression_tracking_requests(
            :timestamp        => @ts.to_i,
            :ip_address       => @ip_address,
            :udid             => @udid,
            :publisher_app_id => @publisher_app_id)
        end
      end

      describe ".queue_click_tracking_requests" do
        it "should queue up the proper GET requests" do
          @offer.queue_click_tracking_requests(
            :timestamp        => @ts.to_i,
            :ip_address       => @ip_address,
            :udid             => @udid,
            :publisher_app_id => @publisher_app_id)
        end
      end

      describe ".queue_conversion_tracking_requests" do
        it "should queue up the proper GET requests" do
          @offer.queue_conversion_tracking_requests(
            :timestamp        => @ts.to_i,
            :ip_address       => @ip_address,
            :udid             => @udid,
            :publisher_app_id => @publisher_app_id)
        end
      end
    end
  end

  describe '#dashboard_statz_url' do
    include Rails.application.routes.url_helpers

    it 'matches URL for Rails statz_url helper' do
      @offer.dashboard_statz_url.should == "#{URI.parse(DASHBOARD_URL).scheme}://#{URI.parse(DASHBOARD_URL).host}/statz/#{@offer.id}"
    end
  end

  describe '#all_blacklisted?' do
    context 'without whitelist' do
      it { should_not be_all_blacklisted }
    end

    context 'with whitelist' do
      before :each do
        subject.stub(:get_countries).and_return(['US'])
      end

      it { should_not be_all_blacklisted }

      context 'with conflicting blacklist' do
        before :each do
          subject.stub(:countries_blacklist).and_return(['US'])
        end

        it { should be_all_blacklisted }
      end
    end
  end

  context "show_rate_algorithms" do
    describe "#calculate_conversion_rate!" do
      it "should calculate the conversion rate and set the attr_accessor variables", :show_rate do
        @offer.recent_clicks.should be_nil
        @offer.recent_installs.should be_nil
        @offer.calculated_conversion_rate.should be_nil
        @offer.cvr_timeframe.should be_nil

        @offer.calculate_conversion_rate!

        @offer.recent_clicks.should_not be_nil
        @offer.recent_installs.should_not be_nil
        @offer.calculated_conversion_rate.should_not be_nil
        @offer.cvr_timeframe.should_not be_nil
      end

      it "should calculate the min conversion rate and set the attr_accessor variable", :show_rate do
        @offer.calculate_conversion_rate!

        @offer.calculated_min_conversion_rate.should be_nil
        @offer.calculate_min_conversion_rate!

        @offer.calculated_min_conversion_rate.should_not be_nil
      end

      it "should raise error for has_low_conversion_rate? if calculate_conversion_rate! has not been called", :show_rate do
        expect {@offer.has_low_conversion_rate?}.to raise_error("Required attributes are not calculated yet")
      end

      it "should not raise error for has_low_conversion_rate? if calculate_conversion_rate! and calculate_min_conversion_rate! has been called", :show_rate do
        @offer.calculate_conversion_rate!
        @offer.calculate_min_conversion_rate!
        expect {@offer.has_low_conversion_rate?}.not_to raise_error
      end

      it "should raise error for calculate_show_rate if calculate_conversion_rate! has not been called", :show_rate do
        expect {@offer.recalculate_show_rate}.to raise_error("Required attributes are not calculated yet")
      end

      it "should not raise error for calculate_show_rate if calculate_conversion_rate! and calculate_min_conversion_rate! has been called", :show_rate do
        @offer.calculate_conversion_rate!
        @offer.calculate_min_conversion_rate!
        expect {@offer.recalculate_show_rate}.to_not raise_error
      end
    end
  end
end
