require 'test_helper'

class OfferDiscountTest < ActiveSupport::TestCase
  should belong_to :partner

  should validate_presence_of :partner
  should validate_presence_of :source
  should validate_presence_of :expires_on
  should validate_presence_of :amount
  should validate_numericality_of :amount

  context "An Admin OfferDiscount" do
    setup do
      @app = Factory(:app)
      @offer = @app.primary_offer
      @partner = @app.partner
    end

    context "with expires_on in the future" do
      setup do
        @offer_discount = @partner.offer_discounts.build(:source => 'Admin', :amount => 10, :expires_on => 1.year.from_now)
      end

      should "trigger premier_discount recalculations for its Partner when saved" do
        original_discount = @partner.premier_discount
        @offer_discount.save!
        @partner.reload
        assert_equal original_discount + 10, @partner.premier_discount
      end

      should "be active" do
        assert @offer_discount.active?
      end

      should "be in the active scope" do
        @offer_discount.save!
        assert OfferDiscount.active.include? @offer_discount
      end

      should "have its expires_on changed to today when deactivated" do
        @offer_discount.save!
        @offer_discount.deactivate!
        assert_equal Time.zone.today, @offer_discount.expires_on
      end
    end

    context "with expires_on in the past" do
      setup do
        @offer_discount = @partner.offer_discounts.build(:source => 'Admin', :amount => 10, :expires_on => 1.year.ago)
      end

      should "not be active" do
        assert !@offer_discount.active?
      end

      should "not be in the active scope" do
        @offer_discount.save!
        assert !OfferDiscount.active.include?(@offer_discount)
      end

      should "do nothing when deactivated" do
        @offer_discount.save!
        assert !@offer_discount.deactivate!
      end
    end
  end

end
