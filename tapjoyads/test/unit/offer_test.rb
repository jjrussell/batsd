require 'test_helper'

class OfferTest < ActiveSupport::TestCase
  context "An App Offer for a free app" do
    setup do
      Offer.any_instance.stubs(:cache) # for some reason the acts_as_cacheable stuff screws up the ability to stub methods as expected
      @offer = Factory(:app).primary_offer.target # need to use the HasOneAssociation's "target" in order for stubbing to work
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

        @offer.expects(:upload_banner_creative!).with("image_data", "480x320").returns(nil)
        @offer.expects(:upload_banner_creative!).with("image_data", "320x480").returns(nil)

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

        clone.expects(:upload_banner_creative!).with("image_data", "480x320").returns(nil)
        clone.expects(:upload_banner_creative!).with("image_data", "320x480").returns(nil)

        clone.save!
      end
    end
  end
end
