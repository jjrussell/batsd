require 'spec_helper'

describe FeaturedContent do
  before :each do
    @featured_content = Factory(:featured_content)
  end

  describe '.belong_to' do
    it { should belong_to :author }
    it { should belong_to :offer }
  end

  describe '.have_one' do
    it { should have_one :tracking_offer }
  end

  describe '#valid?' do
    it { should validate_presence_of :featured_type }
    it { should validate_presence_of :subtitle }
    it { should validate_presence_of :title }
    it { should validate_presence_of :description }
    it { should validate_presence_of :start_date }
    it { should validate_presence_of :end_date }
    it { should validate_presence_of :weight }

    context 'when platforms is blank' do
      before :each do
        @featured_content.platforms = nil
      end

      it "returns false" do
        @featured_content.valid?.should be_false
      end

      it "sets an error message" do
        @featured_content.valid?
        @featured_content.errors.on(:platforms).should == "is not valid JSON"
      end
    end

    context 'when author is nil' do
      before :each do
        @featured_content.update_attributes({ :author => nil })
      end

      context "when the featured_type is 'STAFFPICK'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK] })
        end

        it "returns false" do
          @featured_content.valid?.should be_false
        end

        it "sets an error message" do
          @featured_content.valid?
          @featured_content.errors.on(:author).should == "Please select an author."
        end
      end

      context "when the featured_type is 'PROMO'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::PROMO] })
        end

        it "returns true" do
          @featured_content.valid?.should be_true
        end
      end

      context "when the featured_type is 'NEWS'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::NEWS] })
        end

        it "returns false" do
          @featured_content.valid?.should be_false
        end

        it "sets an error message" do
          @featured_content.valid?
          @featured_content.errors.on(:author).should == "Please select an author."
        end
      end

      context "when the featured_type is 'CONTEST'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::CONTEST] })
        end

        it "returns false" do
          @featured_content.valid?.should be_false
        end

        it "sets an error message" do
          @featured_content.valid?
          @featured_content.errors.on(:author).should == "Please select an author."
        end
      end
    end

    context 'when offer is nil' do
      before :each do
        @featured_content.update_attributes({ :offer => nil })
      end

      context "when the featured_type is 'STAFFPICK'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK] })
        end

        it "returns false" do
          @featured_content.valid?.should be_false
        end

        it "sets an error message" do
          @featured_content.valid?
          @featured_content.errors.on(:offer).should == "Please select an offer/app."
        end
      end

      context "when the featured_type is 'PROMO'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::PROMO] })
        end

        it "returns false" do
          @featured_content.valid?.should be_false
        end

        it "sets an error message" do
          @featured_content.valid?
          @featured_content.errors.on(:offer).should == "Please select an offer/app."
        end
      end

      context "when the featured_type is 'NEWS'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::NEWS] })
        end

        it "returns true" do
          @featured_content.valid?.should be_true
        end
      end

      context "when the featured_type is 'CONTEST'" do
        before :each do
          @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::CONTEST] })
        end

        it "returns true" do
          @featured_content.valid?.should be_true
        end
      end
    end
  end

  describe '#create_tracking_offer' do
    context 'when offer and tracking offerdoes not exist' do
      before :each do
        @featured_content1 = Factory(:featured_content, :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::NEWS], :offer => nil )
      end

      it "doesn't create any tracking offer" do
        @featured_content1.tracking_offer.should be_nil
      end
    end

    context 'when offer not exist but tracking offer already exist' do
      before :each do
        @featured_content.update_attributes({ :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::NEWS], :offer => nil })
        @featured_content.reload
      end

      it "destroys existing tracking offer" do
        @featured_content.tracking_offer.should be_nil
      end
    end

    context 'when offer exists' do
      it "creates a tracking offer" do
        @featured_content.tracking_offer.should be_present
      end

      it "sets the tracking_offer's url with offer.url value" do
        @featured_content.tracking_offer.url.should == @featured_content.offer.url
      end

      it "sets the tracking_offer's device_types with platforms value" do
        @featured_content.tracking_offer.device_types.should == @featured_content.platforms
      end

      it "sets the tracking_offer's rewarded to be false" do
        @featured_content.tracking_offer.rewarded.should be_false
      end

      context 'when updating a tracking offer' do
        before :each do
          @old_platforms = @featured_content.platforms
          @featured_content.update_attributes({ :platforms => ["android"] })
        end

        it "doesn't keep the old platform" do
          @featured_content.tracking_offer.device_types.should_not == @old_platforms.to_json
        end

        it "updates the tracking_offer's name with new platforms" do
          @featured_content.tracking_offer.device_types.should == @featured_content.platforms
        end
      end
    end
  end

  describe '.with_country_targeting' do
    before :each do
      @featured_content2 = Factory(:featured_content)
      @featured_content2.tracking_offer.countries = %w( GL GD GP GT GY ).to_json
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
        featured_contents = FeaturedContent.with_country_targeting(@geoip_data, @device)
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
