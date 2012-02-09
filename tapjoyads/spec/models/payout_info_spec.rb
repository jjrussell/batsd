require 'spec_helper'

describe PayoutInfo do
  describe '.belongs_to' do
    it { should belong_to(:partner) }
  end

  describe '#valid?' do
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:signature) }
    it { should validate_presence_of(:billing_name) }
    it { should validate_presence_of(:tax_country) }
    it { should validate_presence_of(:account_type) }
    it { should validate_presence_of(:tax_id) }
    it { should validate_presence_of(:company_name) }
    it { should validate_presence_of(:address_1) }
    it { should validate_presence_of(:address_city) }
    it { should validate_presence_of(:address_state) }
    it { should validate_presence_of(:address_postal_code) }
  end

  subject { Factory(:payout_info) }

  context "Payout Info" do
    before :each do
      @info = Factory(:payout_info)
    end

    it "validates bank info if payout_method is ACH or wire" do
      @info.payout_method = 'ach'
      @info.should_not be_valid
      @info.bank_name = @info.bank_account_number = @info.bank_routing_number = "foo"
      @info.should be_valid

      @info.bank_name = @info.bank_account_number = @info.bank_routing_number = nil

      @info.payout_method = 'wire'
      @info.should_not be_valid
      @info.bank_name = @info.bank_account_number = @info.bank_routing_number = "foo"
      @info.should be_valid
    end

    it "validates payout_method is wire for international users" do
      @info.payout_method = 'ach'
      @info.should_not be_valid
      @info.bank_name = @info.bank_account_number = @info.bank_routing_number = "foo"
      @info.should be_valid

      @info.bank_name = @info.bank_account_number = @info.bank_routing_number = nil

      @info.payout_method = 'wire'
      @info.should_not be_valid
      @info.bank_name = @info.bank_account_number = @info.bank_routing_number = "foo"
      @info.should be_valid
    end

    it "validates paypal email if paypal" do
      @info.payout_method = 'paypal'
      @info.should_not be_valid
      @info.paypal_email = 'foo'
      @info.should be_valid
    end
  end
end
