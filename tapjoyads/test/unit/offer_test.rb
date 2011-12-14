require 'test_helper'

class OfferTest < ActiveSupport::TestCase

  should have_many :advertiser_conversions
  should have_many :rank_boosts
  should belong_to :partner
  should belong_to :item

  should validate_presence_of :partner
  should validate_presence_of :item
  should validate_presence_of :name
  should validate_presence_of :url

  should validate_numericality_of :price
  should validate_numericality_of :bid
  should validate_numericality_of :daily_budget
  should validate_numericality_of :overall_budget
  should validate_numericality_of :conversion_rate
  should validate_numericality_of :min_conversion_rate
  should validate_numericality_of :show_rate
  should validate_numericality_of :payment_range_low
  should validate_numericality_of :payment_range_high

  context "An App Offer for a free app" do
    setup do
      Offer.any_instance.stubs(:cache) # for some reason the acts_as_cacheable stuff screws up the ability to stub methods as expected
      @offer = Factory(:app).primary_offer.target # need to use the HasOneAssociation's "target" in order for stubbing to work
    end

    should "update its payment when the bid is changed" do
      @offer.update_attributes({:bid => 500})
      assert_equal 500, @offer.payment
    end

    should "update its payment correctly with respect to premier discounts" do
      @offer.partner.premier_discount = 10
      @offer.update_attributes({:bid => 500})
      assert_equal 450, @offer.payment
    end

    should "not allow bids below min_bid" do
      @offer.bid = @offer.min_bid - 5
      assert !@offer.valid?
    end

    should "reject depending on countries blacklist" do
      device = Factory(:device)
      @offer.item.countries_blacklist = ["GB"]
      geoip_data = { :country => "US" }
      assert !@offer.send(:geoip_reject?, geoip_data, device)
      geoip_data = { :country => "GB" }
      assert @offer.send(:geoip_reject?, geoip_data, device)
    end

    should "reject depending on region" do
      device = Factory(:device)
      @offer.regions = ["CA"]
      geoip_data = { :region => "CA" }
      assert !@offer.send(:geoip_reject?, geoip_data, device)
      geoip_data = { :region => "OR" }
      assert @offer.send(:geoip_reject?, geoip_data, device)
      @offer.regions = []
      assert !@offer.send(:geoip_reject?, geoip_data, device)
    end

    should "return propoer linkshare account url" do
      url = 'http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=TEST&mt=8'
      linkshare_url = @offer.linkshare_url(url)
      assert_equal "#{url}&referrer=tapjoy&partnerId=30&siteID=OxXMC6MRBt4", linkshare_url

      linkshare_url = @offer.linkshare_url(url, 'tradedoubler')
      assert_equal "#{url}&referrer=tapjoy&partnerId=2003&tduid=UK1800811", linkshare_url
    end

    context "with banner_creatives" do
      setup do
        @offer.featured = true
        @offer.banner_creatives = %w(480x320 320x480)
      end

      should "fail if asset data not provided" do
        assert !@offer.save
        assert_equal "480x320 custom creative file not provided.", @offer.errors[:custom_creative_480x320_blob]
        assert_equal "320x480 custom creative file not provided.", @offer.errors[:custom_creative_320x480_blob]
      end

      should "upload assets to s3 when data is provided" do
        @offer.banner_creative_480x320_blob = "image_data"
        @offer.banner_creative_320x480_blob = "image_data"

        @offer.expects(:upload_banner_creative!).with("image_data", "480x320", "jpeg").returns(nil)
        @offer.expects(:upload_banner_creative!).with("image_data", "320x480", "jpeg").returns(nil)

        @offer.save!
      end

      should "copy s3 assets over when cloned" do
        class S3Object
          def read; return "image_data"; end
        end

        @offer.stubs(:banner_creative_s3_object).with("480x320").returns(S3Object.new)
        @offer.stubs(:banner_creative_s3_object).with("320x480").returns(S3Object.new)

        clone = @offer.clone
        clone.bid = clone.min_bid

        clone.expects(:upload_banner_creative!).with("image_data", "480x320", "jpeg").returns(nil)
        clone.expects(:upload_banner_creative!).with("image_data", "320x480", "jpeg").returns(nil)

        clone.save!
      end
    end
  end
end
