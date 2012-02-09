require 'spec_helper'

describe VideoButton do

  describe '.belongs_to' do
    it { should belong_to :video_offer }
  end

  describe '#valid?' do
    it { should validate_presence_of :url }
    it { should validate_presence_of :name }

    it { should validate_numericality_of :ordinal }
  end

  context "A Video button" do
    before :each do
      @video_button = Factory(:video_button)
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
  end
end
