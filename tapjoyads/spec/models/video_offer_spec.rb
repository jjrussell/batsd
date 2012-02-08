require 'spec_helper'

describe VideoOffer do
  before :each do
    fake_the_web
  end

  context 'when associating' do
    it 'has many' do
      should have_many :offers
      should have_many :video_buttons
    end

    it 'has one' do
      should have_one :primary_offer
    end

    it 'belongs to' do
      should belong_to :partner
    end
  end

  context 'when validating' do
    it 'validates presence of' do
      should validate_presence_of :partner
      should validate_presence_of :name
    end
  end

  context "A Video Offer" do
    before :each do
      @video_offer = Factory(:video_offer)
    end

    it "updates video_offer's name" do
      @video_offer.update_attributes({:name => 'changed_offer_name_1'})
      @video_offer.name.should == 'changed_offer_name_1'
    end

    it "updates video_offer's hidden field" do
      @video_offer.update_attributes({:hidden => true})
      @video_offer.should be_hidden
    end

    it "has value in video_url after video_offer created" do
      @video_url = Offer.get_video_url({:video_id => @video_offer.id})
      @video_offer.video_url.should == @video_url
    end
  end

  context "A Video Offer with a primary_offer" do
    before :each do
      @video_offer = Factory(:video_offer)
      @offer = @video_offer.primary_offer
    end

    it "updates the primary_offer's name when video_offer's name is changed" do
      @video_offer.update_attributes({:name => 'changed_offer_name_2'})
      @offer.update_attributes({:name => 'changed_offer_name_2'})
      @video_offer.reload
      @offer.name.should == 'changed_offer_name_2'
    end

    it "has value stored in url of the primary_offer after video_offer created" do
      @video_url = Offer.get_video_url({:video_id => @video_offer.id})
      @offer.url.should == @video_url
    end
  end

  context "A Video Offer with multiple video_buttons" do
    before :each do
      @video_offer = Factory(:video_offer)
      @video_button_1 = @video_offer.video_buttons.build
      @video_button_1.name = "button 1"
      @video_button_1.url = "http://www.tapjoy.com"
      @video_button_1.ordinal = 1
      @video_button_1.save!
      @video_button_2 = @video_offer.video_buttons.build
      @video_button_2.name = "button 2"
      @video_button_2.url = "http://www.tapjoy.com"
      @video_button_2.ordinal = 2
      @video_button_2.save!
      @video_button_3 = @video_offer.video_buttons.build
      @video_button_3.name = "button 3"
      @video_button_3.url = "http://www.tapjoy.com"
      @video_button_3.ordinal = 3
      @video_button_3.save!
      @video_offer.reload
    end

    it "has only 2 enabled button" do
      @video_offer.video_buttons.enabled.size.should == 3
      @video_offer.should_not be_valid_for_update_buttons

      @video_button_3.enabled = false
      @video_button_3.save!
      @video_offer.reload
      @video_offer.video_buttons.enabled.size.should == 2
      @video_offer.should be_valid_for_update_buttons
    end
  end
end
