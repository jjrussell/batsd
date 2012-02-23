require 'spec_helper'

describe RankBoost do
  describe '.belongs_to' do
    it { should belong_to :offer }
  end

  describe '#valid?' do
    it { should validate_presence_of :start_time }
    it { should validate_presence_of :end_time }
    it { should validate_presence_of :offer }
    it { should validate_numericality_of :amount }
  end

  before :each do
    @rank_boost = Factory(:rank_boost)
  end

  it "has its offer's partner_id" do
    @rank_boost.partner_id.should == @rank_boost.offer.partner_id
  end

  context "starting before now and ending after now" do
    before :each do
      @rank_boost = Factory(:rank_boost, :start_time => 1.hour.ago, :end_time => 1.hour.from_now)
    end

    it "is active" do
      @rank_boost.should be_active
    end

    it "is in the active scope" do
      RankBoost.active.should include @rank_boost
    end

    context "that is deactivated" do
      before :each do
        @rank_boost.deactivate!
      end

      it "is no longer active" do
        @rank_boost.should_not be_active
      end

      it "is not in the active scope" do
        RankBoost.active.should_not include @rank_boost
      end
    end
  end

  context "with end_time before start_time" do
    before :each do
      @rank_boost = Factory.build(:rank_boost, :start_time => 1.hour.ago, :end_time => 2.hours.ago)
    end

    it "is not valid" do
      @rank_boost.should_not be_valid
    end
  end

end
