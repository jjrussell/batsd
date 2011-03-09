require 'test_helper'

class PayoutInfoTest < ActiveSupport::TestCase
  should validate_presence_of(:partner)
 # should validate_uniqueness_of(:partner)
  should belong_to(:partner)

  subject { Factory(:payout_info) }

  context "Payout Info" do
    setup do
      @info = Factory(:payout_info)
    end
  end
end
