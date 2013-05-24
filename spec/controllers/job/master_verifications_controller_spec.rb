require 'spec_helper'

describe Job::MasterVerificationsController do
  describe '#check_partner_balances' do
    before :each do
      @partner = FactoryGirl.create(:partner)
      @controller.stub(:send_notifications)
      @controller.stub(:check_today?).and_return(true)
      @controller.stub(:check_mismatch)
    end

    it 'calls check_mismatch' do
      @controller.should_receive(:check_mismatch).exactly(Partner.count).times
      @controller.send :check_partner_balances
    end

    context 'when today is not the day to check' do
      before :each do
        @controller.stub(:check_today?).and_return(false)
      end

      it 'does not call check_mismatch' do
        @controller.should_receive(:check_mismatch).never
        @controller.send :check_partner_balances
      end
    end
  end

  describe '#check_mismatch' do
    before :each do
      @partner = FactoryGirl.create(:partner)
      Partner.stub(:verify_balances).and_return(@partner)

      def @controller.balance_mismatches_count
        balance_mismatches.length
      end

      def @controller.earnings_mismatches_count
        earnings_mismatches.length
      end
    end

    it 'does not add to balance mismatches' do
      expect {
        @controller.send(:check_mismatch, @partner.id)
      }.to_not change(@controller, :balance_mismatches_count)
    end

    it 'does not add to pending earnings mismatches' do
      expect {
        @controller.send(:check_mismatch, @partner.id)
      }.to_not change(@controller, :earnings_mismatches_count)
    end

    context 'with mismatch' do
      context 'on balance' do
        before :each do
          @partner.balance += 100
        end

        it 'adds to balance mismatches' do
          expect {
            @controller.send(:check_mismatch, @partner.id)
          }.to change(@controller, :balance_mismatches_count).from(0).to(1)
        end
      end

      context 'on pending earnings' do
        before :each do
          @partner.pending_earnings += 200
        end

        it 'adds to earnings mismatches' do
          expect {
            @controller.send(:check_mismatch, @partner.id)
          }.to change(@controller, :earnings_mismatches_count).from(0).to(1)
        end
      end
    end
  end

  describe '#send_notification' do
    before :each do
      TapjoyMailer.stub(:deliver_partner_money_mismatch)
    end

    it 'does not send email without mismatches' do
      TapjoyMailer.should_receive(:deliver_partner_money_mismatch).never
    end

    context 'with mismatches' do
      context 'on balance' do
        before :each do
          @controller.balance_mismatches = [1]
        end

        it 'sends email' do
          TapjoyMailer.should_receive(:deliver_partner_money_mismatch).with([1], []).once
          @controller.send(:send_notification)
        end
      end

      context 'on pending earnings' do
        before :each do
          @controller.earnings_mismatches = [2]
        end

        it 'sends email' do
          TapjoyMailer.should_receive(:deliver_partner_money_mismatch).with([], [2]).once
          @controller.send(:send_notification)
        end
      end
    end
  end
end
