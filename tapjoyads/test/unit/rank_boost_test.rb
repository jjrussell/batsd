require 'test_helper'

class RankBoostTest < ActiveSupport::TestCase
  should belong_to :offer

  should validate_presence_of :start_time
  should validate_presence_of :end_time
  should validate_presence_of :offer
  should validate_numericality_of :amount

  context "A RankBoost" do
    setup do
      @rank_boost = Factory(:rank_boost)
    end

    should "have its offer's partner_id" do
      assert_equal @rank_boost.offer.partner_id, @rank_boost.partner_id
    end

    context "starting before now and ending after now" do
      setup do
        @rank_boost = Factory(:rank_boost, :start_time => 1.hour.ago, :end_time => 1.hour.from_now)
      end

      should "be active" do
        assert @rank_boost.active?
      end

      should "be in the active scope" do
        assert RankBoost.active.include?(@rank_boost)
      end

      context "that is deactivated" do
        setup do
          @rank_boost.deactivate!
        end

        should "no longer be active" do
          assert !@rank_boost.active?
        end

        should "not be in the active scope" do
          assert !RankBoost.active.include?(@rank_boost)
        end
      end
    end
  end

  context "A RankBoost with end_time before start_time" do
    setup do
      @rank_boost = Factory.build(:rank_boost, :start_time => 1.hour.ago, :end_time => 2.hours.ago)
    end

    should "not be valid" do
      assert !@rank_boost.valid?
    end
  end

end
