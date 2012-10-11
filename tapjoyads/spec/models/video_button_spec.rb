require 'spec_helper'

describe VideoButton do
  let(:video_button) { FactoryGirl.create(:video_button) }

  subject { video_button }

  describe '.belongs_to' do
    it { should belong_to(:video_offer) }
  end

  describe '#valid?' do
    it { should_not validate_presence_of(:url) }
    it { should validate_presence_of(:name) }

    it { should validate_numericality_of(:ordinal) }
  end

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

  describe '#tracking_item_options' do
    let(:app) { video_button.tracking_item }
    subject { video_button.tracking_item_options(app) }

    it { should have_key(:payment) }
    it { should have_key(:reward_value) }
    it { should have_key(:rewarded) }
  end

  describe '#update_tracking_offer' do
    let(:offer) { subject.tracking_offer }

    it 'is called when a record is saved' do
      subject.should_receive(:update_tracking_offer)
      subject.save
    end

    it 'updates the tracking offer if #tracking_item_options is not nil' do
      subject.stub(:tracking_item_options => {})
      offer.should_receive(:update_attributes)
      subject.stub(:tracking_offer => offer)
      subject.send(:update_tracking_offer)
    end

    it 'does not update the tracking offer if #tracking_item_options is nil' do
      subject.stub(:tracking_item_options => nil)
      offer.should_not_receive(:update_attributes)
      subject.stub(:tracking_offer => offer)
      subject.send(:update_tracking_offer)
    end
  end
end
