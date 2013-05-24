require 'spec_helper'

describe VideoOffer do
  subject { FactoryGirl.create(:video_offer) }
  before(:each) do
    subject.stub(:video_exists => true, :cache => true)
  end

  context 'when associating' do
    it { should have_many :offers }
    it { should have_many :video_buttons }
    it { should have_one :primary_offer }
    it { should belong_to :partner }
  end

  context 'creation' do
    it 'should allow setting of primary_offer_creation_attributes' do
      @offer = FactoryGirl.build(:video_offer)
      @offer.primary_offer_creation_attributes = {:featured_ad_content => 'Some Content'}

      @offer.save!
      @offer.primary_offer.featured_ad_content.should == 'Some Content'
    end
  end


  context 'when validating' do
    it { should validate_presence_of :partner }
    it { should validate_presence_of :name }
  end

  context "with a primary_offer" do
    let(:offer) { subject.primary_offer }
    let(:name) { 'changed_offer_name_2' }

    it "updates the primary_offer's name when video_offer's name is changed" do
      subject.update_attributes!(:name => name)
      offer.reload
      offer.name.should == name
    end

    it "has value stored in url of the primary_offer after video_offer created" do
      offer.url.should == subject.video_url
    end
  end

  context "with multiple video_buttons" do
    subject { FactoryGirl.create(:video_offer, :app_targeting => app_targeting) }
    let(:app_targeting) { false }
    let(:buttons) do
      3.times.map do |i|
        FactoryGirl.create(:video_button, :video_offer => subject, :ordinal => i)
      end.tap { subject.reload }
    end

    context 'given three enabled buttons' do
      before(:each) { buttons } # Force create the buttons

      it 'makes buttons enabled by default' do
        subject.video_buttons.enabled.size.should == 3
      end
    end

    context 'given two enabled buttons (one of which was formerly enabled)' do
      let(:button) { buttons.last }

      before(:each) do
        button.enabled = false
        button.save!
        subject.reload
      end

      it 'correctly tracks disabled buttons' do
        subject.video_buttons.enabled.size.should == 2
      end
    end

    describe '#video_buttons_for_device_type' do
      let(:platform_buttons) do
        types = [%w(iphone android), %w(iphone), %w(android)]
        platforms = Hash[buttons.map do |button|
          type = types.shift
          # ensure that tracking_offer.enabled? == true
          button.tracking_offer.update_attributes!(:device_types => type.to_json,
                                                  :tapjoy_enabled => true)
          button.tracking_offer.update_attributes!(:rewarded => true, :reward_value => 1) if type.size > 1

          [(type.size > 1 ? 'rewarded' : type), button]
        end]
        subject.reload
        platforms
      end

      context 'with an iphone device' do
        let(:device) { 'iphone' }
        let(:filtered_out) { platform_buttons['android'] }

        it 'filters out non-iphone offers' do
          subject.video_buttons_for_device_type(device).should_not include(filtered_out)
        end

        context 'and a rewarded PPI button' do
          let(:filtered_out) { platform_buttons['rewarded'] }

          it 'filters out the rewarded install offer' do
            subject.video_buttons_for_device_type(device).should_not include(filtered_out)
          end
        end

        context 'and a rewarded non-PPI button' do
          let(:filtered_out) { platform_buttons['rewarded'] }
          before(:each) do
            gen_offer = Factory(:generic_offer)
            # ensure that tracking_offer.enabled? == true
            gen_offer.primary_offer.update_attribute(:reward_value, 1)

            filtered_out.tracking_item = gen_offer
            # ensure that tracking_offer.enabled? == true
            filtered_out.tracking_offer.update_attribute(:user_enabled, true)

            filtered_out.save!
          end

          it 'does not filter out the rewarded offer' do
            subject.video_buttons_for_device_type(device).should include(filtered_out)
          end
        end
      end

      context 'with an itouch device and a rewarded install offer' do
        let(:device) { 'itouch' }
        let(:filtered_out) { platform_buttons['rewarded'] }

        it 'filters out the rewarded install offer' do
          subject.video_buttons_for_device_type(device).should_not include(filtered_out)
        end
      end

      context 'with an ipad device and a rewarded install offer' do
        let(:device) { 'ipad' }
        let(:filtered_out) { platform_buttons['rewarded'] }

        it 'filters out the rewarded install offer' do
          subject.video_buttons_for_device_type(device).should_not include(filtered_out)
        end
      end

      context 'with an android device' do
        let(:device) { 'android' }
        let(:filtered_out) { platform_buttons['iphone'] }

        it 'filters out non-android offers' do
          subject.video_buttons_for_device_type(device).should_not include(filtered_out)
        end
      end

      context 'with a non-mobile device' do
        before(:each) { buttons } # Force creation of buttons
        it 'does not filter any buttons out' do
          subject.video_buttons_for_device_type(nil).length.should == 3
        end
      end
    end

    describe '#distribution_reject?' do
      context "when not app_targeting" do
        let(:app_targeting) { false }

        context "without video buttons for specified store" do
          it "should not reject" do
            subject.distribution_reject?('astore').should be_false
          end
        end

        context "with video buttons for specified store" do
          it "should not reject" do
            subject.distribution_reject?('astore').should be_false
          end
        end
      end

      context "when app_targeting" do
        let(:app_targeting) { true }

        context "without video buttons for specified store" do
          it "should reject" do
            subject.distribution_reject?('astore').should be_true
          end
        end

        context "with video button for specified store" do
          it "should not reject" do
            subject.distribution_reject?(buttons.last.tracking_offer.app_metadata.store_name).should be_false
          end
        end
      end
    end
  end

  describe '#available_trackable_offers' do
    let(:button) { FactoryGirl.build(:video_button, :video_offer => subject) }

    context 'given an app' do
      let(:app) { FactoryGirl.create(:app, :partner => subject.partner) }
      let(:offer) { app.primary_offer }

      context 'when the parter has a disabled app offer' do
        before(:each) { offer.update_attributes!(:tapjoy_enabled => false) }

        it 'does not include the disabled app' do
          subject.available_trackable_offers(button).should_not include(offer)
        end
      end

      context 'when the partner has an enabled app' do
        before(:each) { offer.update_attributes!(:tapjoy_enabled => true) }

        it 'includes the enabled app' do
          subject.available_trackable_offers(button).should include(offer)
        end

        context 'and a button exists with the app' do
          before(:each) do
            button.tracking_source_offer = offer
            button.save!
          end

          context 'given the same button' do
            it 'includes the app' do
              subject.available_trackable_offers(button).should include(offer)
            end
          end

          context 'given a new button' do
            let(:button2) { FactoryGirl.build(:video_button, :video_offer => subject) }

            it 'does not include the app' do
              subject.available_trackable_offers(button2).should_not include(offer)
            end
          end
        end
      end
    end
  end
end
