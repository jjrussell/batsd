require 'spec_helper'

describe CurrencySale do
  def with_attrs(attrs = {})
    FactoryGirl.build(:currency_sale, attrs)
  end

  it { should belong_to(:currency) }

  describe "validations" do
    context "for factory defaults" do
      let(:subject) { with_attrs({}) }
      it { should have(:no).errors }
    end

    context "for multiplier" do
      context "when not set" do
        let(:subject) { with_attrs(:multiplier => nil) }
        it("should have error") { should have(1).errors_on(:multiplier) }
      end

      context "with an unselectable value" do
        [-1, 0, 255].each do |value|
          it "should have dropdown error for #{value}" do
            with_attrs(:multiplier => value).errors_on(:multiplier).should include(I18n.t('text.currency_sale.must_be_dropdown'))
          end
        end
      end

      context "with selectable value" do
        CurrencySale::MULTIPLIER_SELECT.each do |value|
          it "should have no error for #{value}" do
            with_attrs(:multiplier => value).should have(:no).errors
          end
        end
      end
    end

    context "for start_time" do
      context "when not set" do
        let(:subject) { with_attrs(:start_time => nil) }
        it("should have an error") { should have(1).errors_on(:start_time) }
      end
    end

    context "for end_time" do
      context "when not set" do
        let(:subject) { with_attrs(:end_time => nil) }
        it("should have an error") { should have(1).errors_on(:end_time) }
      end

      context "when < start_time" do
        let(:subject) { with_attrs(:end_time => 10.minutes.from_now, :start_time => 30.minutes.from_now) }
        it("should have an error") { should have(1).errors_on(:end_time) }
        it { subject.errors_on(:end_time).should include(I18n.t('text.currency_sale.start_before_end_error')) }
      end

      context "when start_time is not set" do
        let(:subject) { with_attrs(:end_time => 1.hour.from_now, :start_time => nil) }
        it { should have(:no).errors_on(:end_time) }
      end
    end

    context "for base" do
      let(:base_errors) { subject.errors_on(:base) }
      let(:time_travel_error) { I18n.t('text.currency_sale.time_travel_fail') }

      context "with start_time in the recent past" do
        let(:subject) { with_attrs(:start_time => (CurrencySale::START_TIME_ALLOWANCE.ago + 1.minute)) }
        it { should have(:no).errors }
      end

      context "with start_time older than the recent past" do
        let(:subject) { with_attrs(:start_time => (CurrencySale::START_TIME_ALLOWANCE.ago - 1.minute)) }
        it("should have 'time travel' error") { base_errors.should include(time_travel_error) }
      end

      context "with start_time in the future" do
        let(:subject) { with_attrs(:start_time => 1.hour.from_now) }
        it { should have(:no).errors }
      end

      context "with end_date in the past" do
        let(:subject) { with_attrs(:start_time => 10.minutes.ago, :end_time => 1.minute.ago) }
        it("should have 'time travel' error") { base_errors.should include(time_travel_error) }
      end

      context "when an overlapping sale exists" do
        let(:currency) { FactoryGirl.create(:currency) }
        let(:sale) { FactoryGirl.create(:currency_sale, :currency_id => currency) }
        let(:subject) { with_attrs(:currency_id => currency, :start_time => sale.end_time - 1.minute, :end_time => sale.end_time + 5.minutes) }
        it("should have overlap error") { base_errors.should include(I18n.t('text.currency_sale.overlap_error')) }

        it { currency.should == subject.currency}
      end

      context "when a non-overlapping sale exists" do
        let(:currency) { FactoryGirl.create(:currency) }
        let(:sale) { FactoryGirl.create(:currency_sale, :currency_id => currency) }
        let(:subject) { with_attrs(:currency_id => currency, :start_time => sale.end_time + 1.minute, :end_time => sale.end_time + 5.minutes) }

        it { should have(:no).errors }
      end
    end

    context "for sales created in the past" do
      let(:subject) { Timecop.at_time(1.day.ago) {
        FactoryGirl.create(:currency_sale, :start_time => 1.hour.from_now, :end_time => 2.hours.from_now)
      } }

      it "should remain valid" do
        should have(:no).errors
      end
    end
  end

  describe '#past?' do
    context 'when time range entirely in the past' do
      let(:subject) { with_attrs(:start_time => 4.days.ago, :end_time => 3.days.ago) }
      it { should be_past }
    end

    context 'when time range partially in the past' do
      let(:subject) { with_attrs(:start_time => 4.days.ago, :end_time => 1.days.from_now) }
      it { should_not be_past }
    end

    context 'when time range in the future' do
      let(:subject) { with_attrs(:start_time => 1.days.from_now, :end_time => 4.days.from_now) }
      it { should_not be_past }
    end
  end

  describe "" do
    def create_sale(time = Time.current)
      Timecop.at_time(time) { FactoryGirl.create(:currency_sale, :start_time => 1.minute.ago, :end_time => 1.hour.from_now) }
    end

    let(:active_sale) { create_sale }
    let(:past_sale)   { create_sale(2.days.ago) }
    let(:future_sale) { create_sale(2.days.from_now) }

    describe ".active" do
      let(:subject) { CurrencySale.active }

      it { should include(active_sale) }
      it { should_not include(past_sale) }
      it { should_not include(future_sale) }
    end

    describe ".past" do
      let(:subject) { CurrencySale.past }

      it { should_not include(active_sale) }
      it { should include(past_sale) }
      it { should_not include(future_sale) }
    end

    describe ".future" do
      let(:subject) { CurrencySale.future }

      it { should_not include(active_sale) }
      it { should_not include(past_sale) }
      it { should include(future_sale) }
    end
  end

  describe "#save" do
    let(:currency) {FactoryGirl.create(:currency)}
    let(:sale) { FactoryGirl.build(:currency_sale, :currency_id => currency, :multiplier => 3.0, :end_time => 30.minutes.from_now, :start_time => 10.minutes.from_now) }

    it "should cache the currency" do
      Currency.any_instance.should_receive(:cache)
      sale.save
    end
  end
end
