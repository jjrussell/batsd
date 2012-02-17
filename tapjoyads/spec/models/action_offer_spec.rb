require 'spec_helper'

describe ActionOffer do
  subject { Factory :action_offer }
  it { should have_many :offers }
  it { should have_one :primary_offer }
  it { should belong_to :partner }
  it { should belong_to :app }

  it { should validate_presence_of :partner }
  it { should validate_presence_of :app }
  it { should validate_presence_of :instructions }
  it { should validate_numericality_of :price }

  it "should accept nested attributes for primary_offer" do
    subject.should respond_to(:primary_offer_attributes=)
  end

  it "should delegate user_enabled?, tapjoy_enabled?, bid, min_bid, and daily_budget to primary_offer" do
    delegated_methods = [ :user_enabled?, :tapjoy_enabled?, :bid, :min_bid, :daily_budget ]
    delegated_methods.each do |dm|
      subject.should respond_to dm
    end
  end

  describe "ActionOffer when updated" do
    before :each do
      subject.name = "this is a new name"
      subject.save!
    end

    it "should update its associated Offers" do
      subject.offers.each do |offer|
        offer.name.should == "this is a new name"
      end
    end
  end
end
