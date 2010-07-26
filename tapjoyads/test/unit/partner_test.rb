require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  subject { Factory(:partner) }
  
  should have_many(:orders)
  should have_many(:payouts)
  should have_many(:partner_assignments)
  should have_many(:users).through(:partner_assignments)
  should have_many(:apps)
  should have_many(:email_offers)
  should have_many(:rating_offers)
  should have_many(:offerpal_offers)
  should have_many(:offers)
  should have_many(:publisher_conversions).through(:apps)
  should have_many(:advertiser_conversions).through(:offers)
  should have_many(:monthly_accountings)
  
  should validate_numericality_of(:balance)
  should validate_numericality_of(:pending_earnings)
  should validate_numericality_of(:next_payout_amount)
  
  context "A Partner" do
    context "with monthly payouts" do
      setup do
        @partner = Factory(:partner, :pending_earnings => 100000)
      end
      
      should "determine payout cutoff dates from a reference date" do
        assert_equal Time.zone.parse('2010-01-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-02'))
        assert_equal Time.zone.parse('2010-01-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-03'))
        assert_equal Time.zone.parse('2010-02-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-04'))
        assert_equal Time.zone.parse('2010-02-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-05'))
      end
      
      should "calculate the next payout amount" do
        
      end
    end
    
    context "with semimonthly payouts" do
      setup do
        @partner = Factory(:partner, :payout_frequency => 'semimonthly')
      end
      
      should "determine payout cutoff dates from a reference date" do
        assert_equal Time.zone.parse('2010-02-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-17'))
        assert_equal Time.zone.parse('2010-02-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-18'))
        assert_equal Time.zone.parse('2010-02-16'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-19'))
        assert_equal Time.zone.parse('2010-02-16'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-20'))
      end
    end
  end
end
