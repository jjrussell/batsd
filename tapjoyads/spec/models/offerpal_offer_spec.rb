require 'spec_helper'

describe OfferpalOffer do

  subject { Factory(:offerpal_offer) }

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
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:offerpal_id) }
    it { should validate_uniqueness_of(:offerpal_id) }
  end

end
