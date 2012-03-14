require 'spec_helper'

describe Partner do
  subject { Factory(:partner) }

  it 'associates' do
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
    should have_many(:publisher_conversions)
    should have_many(:advertiser_conversions)
    should have_many(:monthly_accountings)
    should have_many(:global_promoted_offers)
    should belong_to(:client)
  end

  it 'validates' do
    should validate_numericality_of(:balance)
    should validate_numericality_of(:pending_earnings)
    should validate_numericality_of(:next_payout_amount)
    should validate_numericality_of(:rev_share)
    should validate_numericality_of(:direct_pay_share)
  end

  describe 'A Partner' do
    before :each do
      mock_slave = mock()
      mock_slave.stubs(:execute)
      Partner.stubs(:slave_connection).returns(mock_slave)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000)
      @app = Factory(:app, :partner => @partner)
      cutoff_date = @partner.payout_cutoff_date
      Factory(:conversion, :publisher_app => @app, :publisher_amount => 100, :created_at => (cutoff_date - 1))
      Factory(:conversion, :publisher_app => @app, :publisher_amount => 100, :created_at => cutoff_date)
      Factory(:conversion, :publisher_app => @app, :publisher_amount => 100, :created_at => (cutoff_date + 1))
      @partner.reload
    end

    it 'adds account_mgr as account manager' do
      manager_role = Factory(:user_role, :name => "account_mgr")
      manager_user = Factory(:user, :user_roles => [manager_role])
      @partner.users << manager_user
      @partner.account_managers.length.should == 1
    end

    it 'adds normal users but not as account manager' do
      @partner.users << Factory(:user)
      @partner.account_managers.length.should == 0
    end

    it 'calculates the next payout amount' do
      @partner.pending_earnings.should == 10300
      Partner.calculate_next_payout_amount(@partner.id).should == 10100
    end

    context 'with MonthlyAccoutings' do
      before :each do
        reference_time = Conversion.accounting_cutoff_time - 1
        monthly_accounting = MonthlyAccounting.new(:partner => @partner, :month => reference_time.month, :year => reference_time.year)
        monthly_accounting.calculate_totals!
      end

      it 'verifies balances' do
        @partner.pending_earnings.should == 10300
        @partner.balance.should == 10000
        p = Partner.verify_balances(@partner.id)
        p.pending_earnings.should == 300
        p.balance.should == 0
      end

      it 'resets balances' do
        @partner.pending_earnings.should == 10300
        @partner.balance.should == 10000
        @partner.reset_balances
        @partner.pending_earnings.should == 300
        @partner.balance.should == 0
      end
    end

    context 'with monthly payouts' do
      before :each do
        @partner.update_attributes({:payout_frequency => 'monthly'})
      end

      it 'determines payout cutoff dates from a reference date' do
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-02')).should == Time.zone.parse('2010-01-01')
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-03')).should == Time.zone.parse('2010-01-01')
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-04')).should == Time.zone.parse('2010-02-01')
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-05')).should == Time.zone.parse('2010-02-01')
      end
    end

    context 'with semimonthly payouts' do
      before :each do
        @partner.update_attributes({:payout_frequency => 'semimonthly'})
      end

      it 'determines payout cutoff dates from a reference date' do
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-17')).should == Time.zone.parse('2010-02-01')
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-18')).should == Time.zone.parse('2010-02-01')
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-19')).should == Time.zone.parse('2010-02-16')
        @partner.payout_cutoff_date(Time.zone.parse('2010-02-20')).should == Time.zone.parse('2010-02-16')
      end
    end

    context 'with currencies' do
      before :each do
        @currency1 = Factory(:currency, :partner => @partner)
        @currency2 = Factory(:currency, :partner => @partner)
      end

      it "updates its currencies's spend_share when saved" do
        @partner.rev_share = 0.42
        @partner.save!

        @currency1.reload
        @currency2.reload
        @currency1.spend_share.should == 0.42
        @currency2.spend_share.should == 0.42
      end

      it "updates its currencies's direct_pay_share when saved" do
        @partner.direct_pay_share = 0.42
        @partner.save!

        @currency1.reload
        @currency2.reload
        @currency1.direct_pay_share.should == 0.42
        @currency2.direct_pay_share.should == 0.42
      end
    end

    context 'without an ExclusivityLevel' do
      context 'who is assigned a ThreeMonth ExclusivityLevel' do
        before :each do
          @partner.set_exclusivity_level! "ThreeMonth"
        end

        it 'is switched to a ThreeMonth ExclusivityLevel' do
          @partner.exclusivity_level.class.should == ThreeMonth
        end

        it 'has an expires_on three months in the future' do
          @partner.exclusivity_expires_on.should == Date.today + 3.months
        end
      end

      it 'raises a InvalidExclusivityLevelError when assigned a NotReal ExclusivityLevel' do
        expect {
          @partner.set_exclusivity_level! "NotReal"
        }.to raise_error(InvalidExclusivityLevelError)
      end

      it 'is not able to set exclusivity_level_type without exclusivity_expires_on' do
        @partner.exclusivity_level_type = "ThreeMonth"
        @partner.should_not be_valid
      end

      it 'is not able to set exclusivity_expires_on without exclusivity_level_type' do
        @partner.exclusivity_expires_on = 3.months.from_now
        @partner.should_not be_valid
      end

    end

    context 'with a SixMonth ExclusivityLevel' do
      before :each do
        @partner.set_exclusivity_level! "SixMonth"
      end

      it 'is not able to switch to a ThreeMonth ExclusivityLevel' do
        @partner.set_exclusivity_level!("ThreeMonth").should be_false
        @partner.reload
        @partner.exclusivity_level.class.should == SixMonth
        @partner.exclusivity_expires_on.should == Date.today + 6.months
      end

      it 'is able to switch to a NineMonth ExclusivityLevel' do
        @partner.set_exclusivity_level!("NineMonth").should be_true
        @partner.reload
        @partner.exclusivity_level.class.should == NineMonth
        @partner.exclusivity_expires_on.should == Date.today + 9.months
      end

      it 'has exclusivity_level and exclusivity_expires_on set to nil when expired' do
        @partner.expire_exclusivity_level!
        @partner.reload
        @partner.exclusivity_level.should be_nil
        @partner.exclusivity_expires_on.should be_nil
      end

      it 'does not need its exclusivity expired' do
        @partner.needs_exclusivity_expired?.should be_false
      end

      context 'with exclusivity_expires_on in the past' do
        before :each do
          @partner.exclusivity_expires_on = 1.month.ago
        end

        it 'needs its exclusivity expired' do
          @partner.needs_exclusivity_expired?.should be_true
        end
      end
    end

    context 'when assigning a reseller user' do
      before :each do
        @partner.users << Factory(:user)
        @reseller = Factory(:reseller)
        @reseller_user = Factory(:user, :reseller => @reseller)
        @currency = Factory(:currency, :partner => @partner)
      end

      it "modifies reseller of partner and partner's dependent records" do
        @partner.users << @reseller_user
        @partner.reload
        @currency.reload
        @app.reload
        @partner.reseller.should == @reseller
        @currency.reseller.should == @reseller
        @app.primary_offer.reseller.should == @reseller

        @partner.remove_user(@reseller_user)
        @partner.reload
        @currency.reload
        @app.reload
        @partner.reseller.should be_nil
        @currency.reseller.should be_nil
        @app.primary_offer.reseller.should be_nil
      end
    end

    context "with promoted offers" do
      before :each do
        @partner = Factory(:partner)
        @offer1 = Factory(:app, :partner => @partner).primary_offer.target
        @offer2 = Factory(:app, :partner => @partner).primary_offer
        @offer3 = Factory(:app, :partner => @partner, :platform => 'android').primary_offer
        @offer4 = Factory(:app, :partner => @partner).primary_offer
        Offer.any_instance.stubs(:can_be_promoted?).returns(true)
      end

      it "returns available offers with correct platform" do
        available_offers = @partner.offers_for_promotion
        available_offers[:windows].should == []
        available_offers[:android].should == [ @offer3 ]
        available_offers[:iphone].should include @offer1
        available_offers[:iphone].should include @offer2
        available_offers[:iphone].should include @offer4
      end
    end
  end
end
