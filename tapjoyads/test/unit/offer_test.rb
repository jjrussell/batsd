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
      @offer = Factory(:app).primary_offer
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
  end

end
