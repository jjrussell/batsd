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

    should "add account_mgr as account manager" do
      manager_role = Factory(:user_role, :name => "account_mgr")
      manager_user = Factory(:user, :user_roles => [manager_role])
      @partner.users << manager_user
      assert_equal 1, @partner.account_managers.length
    end

    should "add agency as account manager" do
      agency_role = Factory(:user_role, :name => "agency")
      agency_user = Factory(:user, :user_roles => [agency_role])
      @partner.users << agency_user
      assert_equal 1, @partner.account_managers.length
    end

    should "add normal users but not as account manager" do
      @partner.users << Factory(:user)
      assert_equal 0, @partner.account_managers.length
    end

    should "calculate the next payout amount" do
      assert_equal 10300, @partner.pending_earnings
      assert_equal 10100, Partner.calculate_next_payout_amount(@partner.id)
    end
    
    should "verify balances" do
      assert_equal 10300, @partner.pending_earnings
      assert_equal 10000, @partner.balance
      p = Partner.verify_balances(@partner.id)
      assert_equal 300, p.pending_earnings
      assert_equal 0, p.balance
    end
    
    should "reset balances" do
      assert_equal 10300, @partner.pending_earnings
      assert_equal 10000, @partner.balance
      @partner.reset_balances
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
    
    context "with currencies" do
      setup do
        @currency1 = Factory(:currency, :partner => @partner)
        @currency2 = Factory(:currency, :partner => @partner)
      end
      
      should "update its currencies's installs_money_share when saved" do
        @partner.installs_money_share = 0.42
        @partner.save!
        
        @currency1.reload
        @currency2.reload
        assert_equal 0.42, @currency1.installs_money_share
        assert_equal 0.42, @currency2.installs_money_share
      end
    end
    
  end
end
