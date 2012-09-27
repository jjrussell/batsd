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

  describe '#get_icon_url' do
    it 'calls Offer.get_icon_url and passes appropriate args' do
      options = { :option1 => true, :option2 => false }
      Offer.should_receive(:get_icon_url).with(options.merge(:icon_id => Offer.hashed_icon_id(subject.id))).once
      subject.get_icon_url(options)
    end
  end

  describe '#save_icon!' do
    it 'calls Offer.upload_icon! and passes appropriate args' do
      image_data = "img"
      Offer.should_receive(:upload_icon!).with(image_data, subject.id)
      subject.save_icon!(image_data)
    end
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
