require 'test_helper'

class VideoOfferTest < ActiveSupport::TestCase
  should have_many :offers
  should have_many :video_buttons
  should have_one :primary_offer

  should belong_to :partner

  should validate_presence_of :partner
  should validate_presence_of :name

  context "A Video Offer" do
    setup do
      @video_offer = Factory(:video_offer)
    end

    should "update video_offer's name" do
      @video_offer.update_attributes({:name => 'changed_offer_name_1'})
      assert_equal 'changed_offer_name_1', @video_offer.name
    end

    should "update video_offer's hidden field" do
      @video_offer.update_attributes({:hidden => true})
      assert @video_offer.hidden?
    end

    should "have value in video_url after video_offer created" do
      @video_url = Offer.get_video_url({:video_id => @video_offer.id})
      assert_equal @video_url, @video_offer.video_url
    end
  end

  context "A Video Offer with a primary_offer" do
    setup do
      @video_offer = Factory(:video_offer)
      @offer = @video_offer.primary_offer
    end

    should "update the primary_offer's name when video_offer's name is changed" do
      @video_offer.update_attributes({:name => 'changed_offer_name_2'})
      @offer.update_attributes({:name => 'changed_offer_name_2'})
      @video_offer.reload
      assert_equal 'changed_offer_name_2', @offer.name
    end

    should "have value stored in url of the primary_offer after video_offer created" do
      @video_url = Offer.get_video_url({:video_id => @video_offer.id})
      assert_equal @video_url, @offer.url
    end
  end

  context "A Video Offer with multiple video_buttons" do
    setup do
      @video_offer = Factory(:video_offer)
      @video_button_1 = @video_offer.video_buttons.build
      @video_button_1.name = "button 1"
      @video_button_1.url = "http://www.tapjoy.com"
      @video_button_1.ordinal = 1
      @video_button_1.save!
      @video_button_2 = @video_offer.video_buttons.build
      @video_button_2.name = "button 2"
      @video_button_2.url = "http://www.tapjoy.com"
      @video_button_2.ordinal = 2
      @video_button_2.save!
      @video_button_3 = @video_offer.video_buttons.build
      @video_button_3.name = "button 3"
      @video_button_3.url = "http://www.tapjoy.com"
      @video_button_3.ordinal = 3
      @video_button_3.save!
      @video_offer.reload
    end

    should "have only 2 enabled button" do
      assert_equal 3, @video_offer.video_buttons.enabled.size
      assert_equal false, @video_offer.is_valid_for_update_buttons?

      @video_button_3.enabled = false
      @video_button_3.save!
      @video_offer.reload
      assert_equal 2, @video_offer.video_buttons.enabled.size
      assert_equal true, @video_offer.is_valid_for_update_buttons?
    end
  end
end
