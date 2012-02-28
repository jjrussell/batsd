require 'spec_helper'

describe VideoButton do

  subject do
    Factory(:video_button)
  end

  describe '.belongs_to' do
    it { should belong_to :video_offer }
  end

  describe '#valid?' do
    it "should require name to be set" do
      pending "failed during Rails 3 integration"
      should validate_presence_of :url
    end
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

end
