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

  subject { FactoryGirl.create(:video_button) }

  it "is by default enabled" do
    subject.read_attribute(:enabled).should == true
  end

  it "updates third party data on offer based on video button" do
    video_offer = VideoOffer.find(subject.video_offer_id)
    offer = video_offer.primary_offer

    subject.xml_for_offer.should == offer.third_party_data

    video_offer.offers.each do |offer|
      subject.xml_for_offer.should == offer.third_party_data
    end
  end

  describe '#update_tracking_offer' do
    it 'is called when a record is saved' do
      subject.should_receive(:update_tracking_offer)
      subject.save
    end

    it 'updates the tracking offer if #tracking_item_options is not nil' do
      subject.stub(:tracking_item_options => {})
      offer = subject.tracking_offer
      offer.should_receive(:update_attributes)
      subject.stub(:tracking_offer => offer)
      subject.send(:update_tracking_offer)
    end

    it 'does not update the tracking offer if #tracking_item_options is nil' do
      subject.stub(:tracking_item_options => nil)
      offer = subject.tracking_offer
      offer.should_not_receive(:update_attributes)
      subject.stub(:tracking_offer => offer)
      subject.send(:update_tracking_offer)
    end
  end
end
