require 'test_helper'

class CurrencyTest < ActiveSupport::TestCase
  subject { Factory(:currency) }
  
  should belong_to(:app)
  should belong_to(:partner)
  
  should validate_presence_of(:app)
  should validate_presence_of(:partner)
  should validate_presence_of(:name)
  should validate_numericality_of(:conversion_rate)
  should validate_numericality_of(:initial_balance)
  should validate_numericality_of(:installs_money_share)
  should validate_numericality_of(:max_age_rating)
  
  context "A Currency" do
    setup do
      @currency = Factory.build(:currency)
    end
    
    context "when dealing with a RatingOffer" do
      setup do
        @offer = Factory(:rating_offer).primary_offer
      end
      
      should "calculate publisher amounts" do
        assert_equal 0, @currency.get_publisher_amount(@offer)
      end
      
      should "calculate advertiser amounts" do
        assert_equal 0, @currency.get_advertiser_amount(@offer)
      end
      
      should "calculate tapjoy amounts" do
        assert_equal 0, @currency.get_tapjoy_amount(@offer)
      end
      
      should "calculate reward amounts" do
        assert_equal 15, @currency.get_reward_amount(@offer)
      end
    end
    
    context "when dealing with an offer from the same partner" do
      setup do
        @offer = Factory(:app, :partner => @currency.partner).primary_offer
        @offer.update_attribute(:payment, 25)
      end
      
      should "calculate publisher amounts" do
        assert_equal 0, @currency.get_publisher_amount(@offer)
      end
      
      should "calculate advertiser amounts" do
        assert_equal 0, @currency.get_advertiser_amount(@offer)
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
        assert_equal 12, @currency.get_publisher_amount(@offer)
      end
      
      should "calculate advertiser amounts" do
        assert_equal -25, @currency.get_advertiser_amount(@offer)
      end
      
      should "calculate tapjoy amounts" do
        assert_equal 13, @currency.get_tapjoy_amount(@offer)
      end
      
      should "calculate reward amounts" do
        assert_equal 12, @currency.get_reward_amount(@offer)
      end
    end
    
    context "when dealing with a displayer offer" do
      setup do
        @offer = Factory(:app).primary_offer
        @offer.update_attribute(:payment, 25)
        @displayer_app = Factory(:app)
      end
      
      should "calculate publisher amounts" do
        assert_equal 6, @currency.get_publisher_amount(@offer, @displayer_app)
      end
      
      should "calculate advertiser amounts" do
        assert_equal -25, @currency.get_advertiser_amount(@offer)
      end
      
      should "calculate tapjoy amounts" do
        assert_equal 9, @currency.get_tapjoy_amount(@offer, @displayer_app)
      end
      
      should "calculate reward amounts" do
        assert_equal 12, @currency.get_reward_amount(@offer)
      end
      
      should "calculate displayer amounts" do
        assert_equal 10, @currency.get_displayer_amount(@offer, @displayer_app)
      end
    end
    
    context "when created" do
      setup do
        partner = Factory(:partner)
        partner.installs_money_share = 0.42
        partner.disabled_partners = "foo"
        @currency.partner = partner
      end
      
      should "have same installs_money_share as its partner" do
        @currency.save!
        assert_equal 0.42, @currency.installs_money_share
      end
      
      should "have the same disabled_partners as its partner" do
        @currency.save!
        assert_equal 'foo', @currency.disabled_partners
      end
    end
    
  end
end
