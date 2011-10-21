require 'test_helper'

class ConversionTest < ActiveSupport::TestCase
  subject { Factory(:conversion) }

  should belong_to(:publisher_app)
  should belong_to(:advertiser_offer)

  should validate_presence_of(:publisher_app)
  should validate_numericality_of(:advertiser_amount)
  should validate_numericality_of(:publisher_amount)
  should validate_numericality_of(:tapjoy_amount)

  context "A Conversion" do
    setup do
      @conversion = Factory.build(:conversion)
      @pub_partner = @conversion.publisher_app.partner
      @adv_partner = @conversion.advertiser_offer.partner
    end

    should "provide a mechanism to set reward_type from a string" do
      assert_equal 1, @conversion.reward_type
      Conversion::REWARD_TYPES.each do |k, v|
        @conversion.reward_type_string = k
        assert_equal v, @conversion.reward_type
      end
    end

    context "when saved" do
      should "update the publisher's pending earnings" do
        assert_equal 0, @pub_partner.pending_earnings
        @conversion.save!
        @pub_partner.reload
        assert_equal 70, @pub_partner.pending_earnings
      end

      should "update the advertiser's balance" do
        assert_equal 0, @adv_partner.balance
        @conversion.save!
        @adv_partner.reload
        assert_equal -100, @adv_partner.balance
      end
    end
  end
end
