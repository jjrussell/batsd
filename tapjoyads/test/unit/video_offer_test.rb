require 'test_helper'

class VideoOfferTest < ActiveSupport::TestCase
  should have_many :offers
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
    
    should "update the primary_offer's hidden field when video_offer's hidden field is changed" do
      @video_offer.update_attributes({:hidden => true})
      @video_offer.reload
      assert @video_offer.hidden?
      assert !@offer.tapjoy_enabled?
    end
    
    should "have value stored in url of the primary_offer after video_offer created" do
      @video_url = Offer.get_video_url({:video_id => @video_offer.id})
      assert_equal @video_url, @offer.url
    end
  end
end