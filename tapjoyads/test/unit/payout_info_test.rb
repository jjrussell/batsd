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

    should "make sure signature is present for US users" do
      @info.tax_country = "some other country"
      assert @info.valid?
      @info.tax_country = "united states"
      assert !@info.valid?
      @info.signature = "signature"
      assert @info.valid?
    end
  end
end
