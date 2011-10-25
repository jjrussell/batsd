require 'test_helper'

class VideoButtonTest < ActiveSupport::TestCase
  should belong_to :video_offer

  should validate_presence_of :url
  should validate_presence_of :name

  should validate_numericality_of :ordinal

  context "A Video button" do
    setup do
      @video_button = Factory(:video_button)
    end

    should "by default enabled" do
      assert_equal true, @video_button.enabled
    end

    should "update offers' third party data based on video button" do
      video_offer = VideoOffer.find(@video_button.video_offer_id)
      offer = video_offer.primary_offer

      assert_equal offer.third_party_data, @video_button.xml_for_offer

      video_offer.offers.each do |offer|
        assert_equal offer.third_party_data, @video_button.xml_for_offer
      end
    end
  end
end
