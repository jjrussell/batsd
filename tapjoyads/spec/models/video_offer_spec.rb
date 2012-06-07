require 'spec_helper'

describe VideoOffer do
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
      @video_offer = FactoryGirl.create(:video_offer)
    end

    it "updates video_offer's name" do
      @video_offer.update_attributes({:name => 'changed_offer_name_1'})
      @video_offer.name.should == 'changed_offer_name_1'
    end

    it "updates video_offer's hidden field" do
      @video_offer.update_attributes({:hidden => true})
      @video_offer.should be_hidden
    end
  end

  context "A Video Offer with a primary_offer" do
    before :each do
      @video_offer = FactoryGirl.create(:video_offer)
      @offer = @video_offer.primary_offer
    end

    it "updates the primary_offer's name when video_offer's name is changed" do
      @video_offer.update_attributes({:name => 'changed_offer_name_2'})
      @offer.update_attributes({:name => 'changed_offer_name_2'})
      @video_offer.reload
      @offer.name.should == 'changed_offer_name_2'
    end

    it "has value stored in url of the primary_offer after video_offer created" do
      @offer.url.should == @video_offer.video_url
    end
  end

  context "A Video Offer with multiple video_buttons" do
    subject {FactoryGirl.create(:video_offer)}

    let(:buttons) do
      3.times do |i|
        button = subject.video_buttons.build
        button.name     = "button #{i}"
        button.url      = 'http://www.tapjoy.com'
        button.ordinal  = i
        button.stub(:update_tracking_offer).and_return(true)
        button.save!
      end
      subject.video_buttons
    end

    context 'given three enabled buttons' do
      before(:each) do
        buttons
        subject.reload
      end

      it 'makes buttons enabled by default' do
        subject.video_buttons.enabled.size.should == 3
      end
    end

    context 'given two enabled buttons (one of which was formerly enabled)' do
      let(:button) {buttons.last}
      before(:each) do
        button.enabled = false
        button.stub(:update_tracking_offer).and_return(true)
        button.save!
        subject.reload
      end

      it 'correctly tracks disabled buttons' do
        subject.video_buttons.enabled.size.should == 2
      end
    end

    #   @video_offer = FactoryGirl.create(:video_offer)
    #   @video_button_1 = @video_offer.video_buttons.build
    #   @video_button_1.name = "button 1"
    #   @video_button_1.url = "http://www.tapjoy.com"
    #   @video_button_1.ordinal = 1
    #   @video_button_1.save!
    #   @video_button_2 = @video_offer.video_buttons.build
    #   @video_button_2.name = "button 2"
    #   @video_button_2.url = "http://www.tapjoy.com"
    #   @video_button_2.ordinal = 2
    #   @video_button_2.save!
    #   @video_button_3 = @video_offer.video_buttons.build
    #   @video_button_3.name = "button 3"
    #   @video_button_3.url = "http://www.tapjoy.com"
    #   @video_button_3.ordinal = 3
    #   @video_button_3.save!
    #   @video_offer.reload

    # it "has only 2 enabled buttons" do
    #   subject.video_buttons.enabled.size.should == 3
    #   subject.should_not be_valid_for_update_buttons

    #   button_3.enabled = false
    #   button_3.save!

    #   subject.reload
    #   subject.video_buttons_enabled.size.should == 2
    #   subject.should be_valid_for_update_buttons
    # end
  end
end
