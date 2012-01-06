require 'test_helper'

class OfferTest < ActiveSupport::TestCas
  context "An App Offer for a free app" do
    setup do
      @offer = Factory(:app).primary_offer.target # need to use the HasOneAssociation's "target" in order for stubbing to work
      @offer.stubs(:cache) # for some reason the acts_as_cacheable stuff screws up the ability to stub methods as expected
    end

    context "with banner_creatives" do
      setup do
        @offer.featured = true
        @offer.banner_creatives = %w(480x320)
        # @offer.banner_creatives = %w(480x320 320x480)
      end

      should "fail if asset data not provided" do
        assert !@offer.save
        assert_equal "480x320 custom creative file not provided.", @offer.errors[:custom_creative_480x320_blob]
        # assert_equal "320x480 custom creative file not provided.", @offer.errors[:custom_creative_320x480_blob]
      end

      should "upload assets to s3 when data is provided" do
        @offer.banner_creative_480x320_blob = "image_data"
        # @offer.banner_creative_320x480_blob = "image_data"

        @offer.expects(:upload_banner_creative!).with("image_data", "480x320", "jpeg").returns(nil)
        # @offer.expects(:upload_banner_creative!).with("image_data", "320x480", "jpeg").returns(nil)

        @offer.save!
      end

      should "copy s3 assets over when cloned" do
        class S3Object
          def read; return "image_data"; end
        end

        @offer.stubs(:banner_creative_s3_object).with("480x320", "jpeg").returns(S3Object.new)
        # @offer.stubs(:banner_creative_s3_object).with("320x480", "jpeg").returns(S3Object.new)

        clone = @offer.clone
        clone.bid = clone.min_bid

        # TODO: uncomment this once bugs are fixed / merged
        # clone.expects(:upload_banner_creative!).with("image_data", "480x320", "jpeg").returns(nil)
        # # clone.expects(:upload_banner_creative!).with("image_data", "320x480", "jpeg").returns(nil)
        #
        # clone.save!

        # TODO: remove the following once bugs are fixed / merged
        assert !clone.save
        assert_equal "480x320 custom creative file not provided.", clone.errors[:custom_creative_480x320_blob]
        # assert_equal "320x480 custom creative file not provided.", clone.errors[:custom_creative_320x480_blob]
      end
    end
  end
end
