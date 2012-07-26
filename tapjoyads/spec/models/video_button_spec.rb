require 'spec_helper'

describe VideoButton do
  describe '.belongs_to' do
    it { should belong_to :video_offer }
  end

  describe '#valid?' do
    it { should_not validate_presence_of :url }
    it { should validate_presence_of :name }

    it { should validate_numericality_of :ordinal }
  end

  before :each do
    @video_button = FactoryGirl.create(:video_button)
  end

  it "is by default enabled" do
    @video_button.enabled.should == true
  end

  it "updates third party data on offer based on video button" do
    video_offer = VideoOffer.find(@video_button.video_offer_id)
    offer = video_offer.primary_offer

    @video_button.xml_for_offer.should == offer.third_party_data

    video_offer.offers.each do |offer|
      @video_button.xml_for_offer.should == offer.third_party_data
    end
  end

  describe '#update_tracking_offer' do
    it 'is called when a record is saved' do
      @video_button.should_receive(:update_tracking_offer)
      @video_button.save
    end

    it 'updates the tracking offer if #tracking_item_options is not nil' do
      @video_button.stub(:tracking_item_options => {})
      offer = @video_button.tracking_offer
      offer.should_receive(:update_attributes)
      @video_button.stub(:tracking_offer => offer)
      @video_button.send(:update_tracking_offer)
    end

    it 'does not update the tracking offer if #tracking_item_options is nil' do
      @video_button.stub(:tracking_item_options => nil)
      offer = @video_button.tracking_offer
      offer.should_not_receive(:update_attributes)
      @video_button.stub(:tracking_offer => offer)
      @video_button.send(:update_tracking_offer)
    end
  end
end
