require 'spec_helper'

describe GenericOffer do

  subject { FactoryGirl.create(:generic_offer) }

  describe '.has_many' do
    it { should have_many(:offers) }
  end

  describe '.has_one' do
    it { should have_one(:primary_offer) }
  end

  describe '.belongs_to' do
    it { should belong_to(:partner) }
  end

  describe '#valid?' do
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:url) }
  end

  before :each do
    @generic_offer = FactoryGirl.create(:generic_offer)
  end

  it 'accepts existing categories' do
    GenericOffer::CATEGORIES.each do |category|
      @generic_offer.category = category
      @generic_offer.should be_valid
    end
  end

  it 'rejects invalid categories' do
    @generic_offer.category = 'invalid'
    @generic_offer.should_not be_valid
  end

end
