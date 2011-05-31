require 'test_helper'

class PayoutInfoTest < ActiveSupport::TestCase
  should validate_presence_of(:partner)
  should validate_presence_of(:signature)
  should validate_presence_of(:billing_name)
  should validate_presence_of(:tax_country)
  should validate_presence_of(:account_type)
  should validate_presence_of(:tax_id)
  should validate_presence_of(:company_name)
  should validate_presence_of(:address_1)
  should validate_presence_of(:address_city)
  should validate_presence_of(:address_state)
  should validate_presence_of(:address_postal_code)
  should belong_to(:partner)

  subject { Factory(:payout_info) }

  context "Payout Info" do
    setup do
      @info = Factory(:payout_info)
    end

    should "validate bank info if payout_method is ACH" do
      @info.payout_method = 'ach'
      assert !@info.valid?
      @info.bank_name = @info.bank_account_number = @info.bank_routing_number = "foo"
      assert @info.valid?
    end
  end
end
