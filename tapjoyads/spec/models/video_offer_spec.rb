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
        Factory(:video_button, :video_offer => subject, :ordinal => i)
      end
      subject.reload
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
        button.save!
        subject.reload
      end

      it 'correctly tracks disabled buttons' do
        subject.video_buttons.enabled.size.should == 2
      end
    end

    describe '#video_buttons_for_device' do
      before(:each) do
        @buttons = {}

        types = [%w(iphone android), %w(iphone), %w(android)]
        buttons.each do |button|
          type = types.shift
          button.tracking_offer.update_attribute(:device_types, type.to_json)
          button.update_attribute(:rewarded, true) if type.size > 1
          @buttons[type.size > 1 ? 'rewarded' : type] = button
        end

        subject.reload
      end

      context 'with an iphone device' do
        let(:device) { 'iphone' }
        let(:filtered_out) { @buttons['android'] }

        it 'filters out non-iphone offers' do
          subject.video_buttons_for_device(device).should_not include(filtered_out)
        end

        context 'and a rewarded PPI button' do
          let(:filtered_out) { @buttons['rewarded'] }

          it 'filters out the rewarded install offer' do
            subject.video_buttons_for_device(device).should_not include(filtered_out)
          end
        end

        context 'and a rewarded non-PPI button' do
          let(:filtered_out) { @buttons['rewarded'] }
          before(:each) do
            filtered_out.tracking_item = Factory(:generic_offer)
            filtered_out.save!
          end

          it 'does not filter out the rewarded offer' do
            subject.video_buttons_for_device(device).should include(filtered_out)
          end
        end
      end

      context 'with an itouch device and a rewarded install offer' do
        let(:device) { 'itouch' }
        let(:filtered_out) { @buttons['rewarded'] }

        it 'filters out the rewarded install offer' do
          subject.video_buttons_for_device(device).should_not include(filtered_out)
        end
      end

      context 'with an ipad device and a rewarded install offer' do
        let(:device) { 'ipad' }
        let(:filtered_out) { @buttons['rewarded'] }

        it 'filters out the rewarded install offer' do
          subject.video_buttons_for_device(device).should_not include(filtered_out)
        end
      end

      context 'with an android device' do
        let(:device) { 'android' }
        let(:filtered_out) { @buttons['iphone'] }

        it 'filters out non-android offers' do
          subject.video_buttons_for_device(device).should_not include(filtered_out)
        end
      end

      context 'with a non-mobile device' do
        it 'does not filter any buttons out' do
          subject.video_buttons_for_device(nil).length.should == 3
        end
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
