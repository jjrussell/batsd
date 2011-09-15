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
  should validate_numericality_of(:rev_share)
  should validate_numericality_of(:direct_pay_share)

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

    should "add normal users but not as account manager" do
      @partner.users << Factory(:user)
      assert_equal 0, @partner.account_managers.length
    end

    should "calculate the next payout amount" do
      assert_equal 10300, @partner.pending_earnings
      assert_equal 10100, Partner.calculate_next_payout_amount(@partner.id)
    end
    
    context "with MonthlyAccoutings" do
      setup do
        reference_time = Conversion.archive_cutoff_time - 1
        monthly_accounting = MonthlyAccounting.new(:partner => @partner, :month => reference_time.month, :year => reference_time.year)
        monthly_accounting.calculate_totals!
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
    end
    
    context "with monthly payouts" do
      setup do
        @partner.update_attributes({:payout_frequency => 'monthly'})
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
        @partner.update_attributes({:payout_frequency => 'semimonthly'})
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
      
      should "update its currencies's spend_share when saved" do
        @partner.rev_share = 0.42
        @partner.save!
        
        @currency1.reload
        @currency2.reload
        assert_equal 0.42, @currency1.spend_share
        assert_equal 0.42, @currency2.spend_share
      end
      
      should "update its currencies's direct_pay_share when saved" do
        @partner.direct_pay_share = 0.42
        @partner.save!
        
        @currency1.reload
        @currency2.reload
        assert_equal 0.42, @currency1.direct_pay_share
        assert_equal 0.42, @currency2.direct_pay_share
      end
    end
    
    context "without an ExclusivityLevel" do
      context "who is assigned a ThreeMonth ExclusivityLevel" do
        setup do
          @partner.set_exclusivity_level! "ThreeMonth"
        end
        
        should "be switched to a ThreeMonth ExclusivityLevel" do
          assert_equal ThreeMonth, @partner.exclusivity_level.class
        end
        
        should "have an expires_on three months in the future" do
          assert_equal Date.today + 3.months, @partner.exclusivity_expires_on
        end
      end
      
      should "raise a InvalidExclusivityLevelError when assigned a NotReal ExclusivityLevel" do
        assert_raise(InvalidExclusivityLevelError) do
          @partner.set_exclusivity_level! "NotReal"
        end
      end
      
      should "not be able to set exclusivity_level_type without exclusivity_expires_on" do
        @partner.exclusivity_level_type = "ThreeMonth"
        assert !@partner.valid?
      end
      
      should "not be able to set exclusivity_expires_on without exclusivity_level_type" do
        @partner.exclusivity_expires_on = 3.months.from_now
        assert !@partner.valid?
      end
      
    end
    
    context "with a SixMonth ExclusivityLevel" do
      setup do
        @partner.set_exclusivity_level! "SixMonth"
      end
      
      should "not be able to switch to a ThreeMonth ExclusivityLevel" do
        assert !@partner.set_exclusivity_level!("ThreeMonth")
        @partner.reload
        assert_equal SixMonth, @partner.exclusivity_level.class
        assert_equal Date.today + 6.months, @partner.exclusivity_expires_on
      end
      
      should "be able to switch to a NineMonth ExclusivityLevel" do
        assert @partner.set_exclusivity_level!("NineMonth")
        @partner.reload
        assert_equal NineMonth, @partner.exclusivity_level.class
        assert_equal Date.today + 9.months, @partner.exclusivity_expires_on
      end
      
      should "have exclusivity_level and exclusivity_expires_on set to nil when expired" do
        @partner.expire_exclusivity_level!
        @partner.reload
        assert_nil @partner.exclusivity_level
        assert_nil @partner.exclusivity_expires_on
      end
      
      should "not need its exclusivity expired" do
        assert !@partner.needs_exclusivity_expired?
      end
      
      context "with exclusivity_expires_on in the past" do
        setup do
          @partner.exclusivity_expires_on = 1.month.ago
        end
        
        should "need its exclusivity expired" do
          assert @partner.needs_exclusivity_expired?
        end
      end
    end
    
  end
end
