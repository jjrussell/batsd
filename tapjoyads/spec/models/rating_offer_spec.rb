require 'spec_helper'

describe RatingOffer do

  subject { Factory(:rating_offer) }

  describe '.has_many' do
    it { should have_many(:offers) }
  end

  describe '.has_one' do
    it { should have_one(:primary_offer) }
  end

  describe '.belongs_to' do
    it { should belong_to(:partner) }
    it { should belong_to(:app) }
  end

  describe '#valid?' do
    it { should validate_presence_of(:partner) }
  end

  context 'A RatingOffer' do
    before :each do
      @rating_offer = Factory(:rating_offer)
    end

    it 'appends the app version to the id' do
      @rating_offer.get_id_with_app_version(nil).should == "#{@rating_offer.id}"
      @rating_offer.get_id_with_app_version('1.0').should == "#{@rating_offer.id}.1.0"
    end
  end

end
