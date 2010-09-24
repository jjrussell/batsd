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
  should have_many(:generic_offers)
  should have_many(:offers)
  should have_many(:publisher_conversions).through(:apps)
  should have_many(:advertiser_conversions).through(:offers)
  should have_many(:monthly_accountings)
  
  should validate_numericality_of(:balance)
  should validate_numericality_of(:pending_earnings)
  should validate_numericality_of(:next_payout_amount)
  
  context "A Partner" do
    setup do
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000)
      app = Factory(:app, :partner => @partner)
      cutoff_date = @partner.payout_cutoff_date
      Factory(:conversion, :publisher_app => app, :publisher_amount => 100, :created_at => (cutoff_date - 1))
      Factory(:conversion, :publisher_app => app, :publisher_amount => 100, :created_at => cutoff_date)
      Factory(:conversion, :publisher_app => app, :publisher_amount => 100, :created_at => (cutoff_date + 1))
      @partner.reload
    end
    
    should "calculate the next payout amount" do
      assert_equal 10300, @partner.pending_earnings
      @partner.calculate_next_payout_amount
      assert_equal 10100, @partner.next_payout_amount
    end
    
    should "recalculate balances" do
      assert_equal 10300, @partner.pending_earnings
      assert_equal 10000, @partner.balance
      @partner.recalculate_balances
      assert_equal 300, @partner.pending_earnings
      assert_equal 0, @partner.balance
    end
    
    context "with monthly payouts" do
      setup do
        @partner.update_attribute(:payout_frequency, 'monthly')
      end
      
      should "determine payout cutoff dates from a reference date" do
        assert_equal Time.zone.parse('2010-01-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-02'))
        assert_equal Time.zone.parse('2010-01-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-03'))
        assert_equal Time.zone.parse('2010-02-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-04'))
        assert_equal Time.zone.parse('2010-02-01'), @partner.payout_cutoff_date(Time.zone.parse('2010-02-05'))
      end
    end
    
    context "with semimonthly payouts" do
      setup do
        @partner.update_attribute(:payout_frequency, 'semimonthly')
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
