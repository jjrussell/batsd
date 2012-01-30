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

  it "should reject depending on mobile country codes" do
    @offer.mobile_country_codes = ["234", "235"]
    geoip_data = { :country => "US" }
    mobile_country_code = "310"
    @offer.send(:geoip_reject?, geoip_data, mobile_country_code).should == true
    geoip_data = { :country => "GB" }
    mobile_country_code = "235"
    @offer.send(:geoip_reject?, geoip_data, mobile_country_code).should == false
  end

  it "should reject depending on countries blacklist" do
    @offer.item.countries_blacklist = ["GB"]
    geoip_data = { :country => "US" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :country => "GB" }
    @offer.send(:geoip_reject?, geoip_data).should == true
  end

  it "should reject depending on region" do
    @offer.regions = ["CA"]
    geoip_data = { :region => "CA" }
    @offer.send(:geoip_reject?, geoip_data).should == false
    geoip_data = { :region => "OR" }
    @offer.send(:geoip_reject?, geoip_data).should == true
    @offer.regions = []
    @offer.send(:geoip_reject?, geoip_data).should == false
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
end
