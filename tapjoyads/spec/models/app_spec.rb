require 'spec_helper'

describe App do
  # Check associations
  it { should have_many :currencies }
  it { should have_many :non_rewarded_featured_offers }
  it { should have_many :non_rewarded_offers }
  it { should have_many :offers }
  it { should have_many :publisher_conversions }
  it { should have_many :rewarded_featured_offers }
  it { should have_one :rating_offer }
  it { should have_one :primary_currency }
  it { should have_one :primary_offer }
  it { should have_one :primary_rewarded_featured_offer }
  it { should have_one :primary_non_rewarded_featured_offer }
  it { should have_one :primary_non_rewarded_offer }
  it { should belong_to :partner }

  # Check validations
  it { should validate_presence_of :partner }
  it { should validate_presence_of :name }

  context "An App" do
    before :each do
      @app = Factory(:app, :price => 200)
    end

    it "should update its offers' bids when its price changes" do
      offer = @app.primary_offer
      @app.update_attributes({:price => 400})
      offer.reload
      offer.bid.should equal(200)
    end
  end

  context "An App with Action Offers" do
    before :each do
      @action_offer = Factory(:action_offer)
      @app = @action_offer.app
    end

    it "should update action offer hidden field" do
      @app.update_attributes({:hidden => true})
      @action_offer.reload
      @action_offer.should be_hidden
      @action_offer.primary_offer.should_not be_tapjoy_enabled
    end

    it "should update action offer bids when its price changes" do
      @app.update_attributes({:price => 400})
      @action_offer.reload
      @action_offer.primary_offer.bid.should equal(200)
    end

    it "should not update action offer bids if it has a prerequisite offer" do
      @action_offer.prerequisite_offer = @app.primary_offer
      @action_offer.save
      offer = @action_offer.primary_offer
      @app.update_attributes({:price => 400})
      offer.reload
      offer.bid.should equal(35)
    end
  end
end
