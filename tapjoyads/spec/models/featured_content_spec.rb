require 'spec_helper'

describe FeaturedContent do
  before :each do
    @partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
    @generic_offer = Factory(:generic_offer, :id => FEATURED_CONTENT_GENERIC_TRACKING_OFFER_ID, :partner => @partner)
    @featured_content = Factory(:featured_content)
  end

  context 'when associating' do
    it { should belong_to :author }
    it { should belong_to :offer }
    it { should have_one :tracking_offer }
  end

  context 'when validating' do
    it { should validate_presence_of :featured_type }
    it { should validate_presence_of :subtitle }
    it { should validate_presence_of :title }
    it { should validate_presence_of :description }
    it { should validate_presence_of :start_date }
    it { should validate_presence_of :end_date }
    it { should validate_presence_of :weight }

    it "throws an error if the platforms is blank" do
      @featured_content.platforms = nil
      @featured_content.should_not be_valid
      @featured_content.errors.on(:platforms).should == "is not valid JSON"
    end

    context 'without author' do
      before :each do
        @featured_content.update_attributes({ :author => nil })
      end

      it "throws an error if the featured_type is 'STAFFPICK'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK] })

        @featured_content.should_not be_valid
        @featured_content.errors.on(:author).should == "Please select an author."
      end

      it "throws no error if the featured_type is 'PROMO'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::PROMO] })

        @featured_content.should be_valid
        @featured_content.errors.on(:author).should == nil
      end

      it "throws an error if the featured_type is 'NEWS'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::NEWS] })

        @featured_content.should_not be_valid
        @featured_content.errors.on(:author).should == "Please select an author."
      end

      it "throws an error if the featured_type is 'CONTEST'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::CONTEST] })

        @featured_content.should_not be_valid
        @featured_content.errors.on(:author).should == "Please select an author."
      end
    end

    context 'without offer' do
      before :each do
        @featured_content.update_attributes({ :offer => nil })
      end

      it "throws an error if the featured_type is 'STAFFPICK'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK] })

        @featured_content.should_not be_valid
        @featured_content.errors.on(:offer).should == "Please select an offer/app."
      end

      it "throws an error if the featured_type is 'PROMO'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::PROMO] })

        @featured_content.should_not be_valid
        @featured_content.errors.on(:offer).should == "Please select an offer/app."
      end

      it "throws no error if the featured_type is 'NEWS'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::NEWS] })

        @featured_content.should be_valid
        @featured_content.errors.on(:offer).should == nil
      end

      it "throws no error if the featured_type is 'CONTEST'" do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::CONTEST] })

        @featured_content.should be_valid
        @featured_content.errors.on(:offer).should == nil
      end
    end
  end

  describe '.create_tracking_offer' do
    context 'when button_url does not exist' do
      it "doesn't create any tracking offer" do
        @featured_content.tracking_offer.should be_nil
      end
    end

    context 'when button_url exists' do
      before :each do
        @featured_content.update_attributes({ :button_url => "test_url" })
      end

      it "creates a tracking offer" do
        @featured_content.tracking_offer.should be_present
        @featured_content.tracking_offer.name.should == "#{@featured_content.title}_#{@featured_content.subtitle}"
        @featured_content.tracking_offer.url.should == @featured_content.button_url
        @featured_content.tracking_offer.device_types.should == @featured_content.platforms
        @featured_content.tracking_offer.third_party_data == @featured_content.id
        @featured_content.tracking_offer.rewarded.should be_false
        @featured_content.tracking_offer.fc_tracking.should be_true
      end

      it "update a tracking offer" do
        old_title = "#{@featured_content.title}_#{@featured_content.subtitle}"
        @featured_content.tracking_offer.name.should == old_title

        @featured_content.update_attributes({ :title => "new_title" })
        @featured_content.tracking_offer.name.should_not == old_title
        @featured_content.tracking_offer.name.should == "#{@featured_content.title}_#{@featured_content.subtitle}"
      end
    end
  end

  describe '.featured_contents_with_country_targeting' do
    before :each do
      @featured_content.update_attributes({ :button_url => "test_url" })

      @featured_content2 = Factory(:featured_content)
      @featured_content2.update_attributes({ :button_url => "test_url" })
      @featured_content2.tracking_offer.countries = ["GL","GD","GP","GT","GY"].to_json
      @featured_content2.tracking_offer.save!
      @featured_content2.reload

      @geoip_data = { :country => "US" }
      @device = Factory(:device)
    end

    context 'when there is country targeting' do
      it 'rejects featured content with different country targeting' do
        @featured_content.tracking_offer.send(:geoip_reject?, @geoip_data, @device).should == false
      end

      it 'accepts featured content within country targeting' do
        @geoip_data[:country] = "GL"
        @featured_content.tracking_offer.send(:geoip_reject?, @geoip_data, @device).should == false
      end

      it 'returns featured content within country targeting' do
        featured_contents = FeaturedContent.featured_contents_with_country_targeting(@geoip_data, @device)
        featured_contents.size.should == 1
      end
    end

    context 'when there is no country targeting' do
      it 'accepts featured content' do
        @featured_content2.tracking_offer.send(:geoip_reject?, @geoip_data, @device).should == true
      end
    end
  end

  describe '#get_default_icon_url' do
    before :each do
      prefix = "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy"
      size = "57"
      icon_id = "dynamic_staff_pick_tool"
      @default_icon_url = "#{prefix}/icons/#{size}/#{icon_id}.jpg"
    end

    context 'when main/secondary url are nil' do
      it "returns default main icon url" do
        @featured_content.get_icon_url("#{@featured_content.id}_main").should == @default_icon_url
      end

      it "returns default secondary icon url" do
        @featured_content.get_icon_url("#{@featured_content.id}_secondary").should == @default_icon_url
      end
    end
  end

end
