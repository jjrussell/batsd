require 'test_helper'

class CurrencyTest < ActiveSupport::TestCase
  subject { Factory(:currency) }
  
  should belong_to(:app)
  should belong_to(:partner)
  
  should validate_presence_of(:app)
  should validate_presence_of(:partner)
  should validate_numericality_of(:conversion_rate)
  should validate_numericality_of(:initial_balance)
  should validate_numericality_of(:offers_money_share)
  should validate_numericality_of(:installs_money_share)
  should validate_numericality_of(:max_age_rating)
  
  context "A Currency" do
    setup do
      @currency = Factory(:currency)
    end
    
    context "when dealing with an OfferpalOffer" do
      setup do
        @offer = Factory(:offerpal_offer).primary_offer
      end
      
      should "calculate the publisher amount" do
        assert_equal 85, @currency.get_publisher_amount(@offer)
      end
      
      should "calculate the advertiser amount" do
        assert_equal -100, @currency.get_advertiser_amount(@offer)
      end
      
      should "calculate the tapjoy amount" do
        assert_equal 15, @currency.get_tapjoy_amount(@offer)
      end
      
      should "calculate the reward amount" do
        assert_equal 85, @currency.get_reward_amount(@offer)
      end
    end
    
    context "when dealing with a RatingOffer" do
      setup do
        @offer = Factory(:rating_offer).primary_offer
      end
      
      should "calculate the reward amount" do
        assert_equal 12, @currency.get_reward_amount(@offer)
      end
    end
    
    context "when dealing with an offer from the same partner" do
      setup do
        @offer = Factory(:app, :partner => @currency.partner).primary_offer
        @offer.update_attribute(:payment, 25)
      end
      
      should "calculate publisher amounts" do
        assert_equal 25, @currency.get_publisher_amount(@offer)
      end
      
      should "calculate advertiser amounts" do
        assert_equal -25, @currency.get_advertiser_amount(@offer)
      end
      
      should "calculate tapjoy amounts" do
        assert_equal 0, @currency.get_tapjoy_amount(@offer)
      end
      
      should "calculate reward amounts" do
        assert_equal 25, @currency.get_reward_amount(@offer)
      end
    end
    
    context "when dealing with any other offer" do
      setup do
        @offer = Factory(:app).primary_offer
        @offer.update_attribute(:payment, 25)
      end
      
      should "calculate publisher amounts" do
        assert_equal 17, @currency.get_publisher_amount(@offer)
      end
      
      should "calculate advertiser amounts" do
        assert_equal -25, @currency.get_advertiser_amount(@offer)
      end
      
      should "calculate tapjoy amounts" do
        assert_equal 8, @currency.get_tapjoy_amount(@offer)
      end
      
      should "calculate reward amounts" do
        assert_equal 17, @currency.get_reward_amount(@offer)
      end
    end
    
  end
end
