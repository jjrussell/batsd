require 'spec_helper'

describe VideoButton do

  subject do
    Factory(:video_button)
  end

  describe '.belongs_to' do
    it { should belong_to :video_offer }
    it { should belong_to :tracking_offer }
  end

  describe '#valid?' do
    it { should validate_presence_of :name }
    it { should validate_numericality_of :ordinal }
  end

  it "is by default enabled" do
    subject.should be_enabled
  end

  it "updates third party data on offer based on video button" do
    video_offer = VideoOffer.find(subject.video_offer_id)
    offer = video_offer.primary_offer

    subject.xml_for_offer.should == offer.third_party_data

    video_offer.offers.each do |offer|
      subject.xml_for_offer.should == offer.third_party_data
    end
  end

   context 'with an item present' do
     before(:each) do
       subject.item = Factory(:generic_offer)
     end

     it 'should validate with an empty url' do
       subject.url = nil
       subject.should be_valid
     end

     it 'should generate a tracking offer' do
       subject.tracking_offer = nil
       subject.save
       subject.tracking_offer.should be_present
     end
   end
end
