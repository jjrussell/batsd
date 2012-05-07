require 'spec_helper'

describe FeaturedContent do
  before :each do
    @featured_content = Factory(:featured_content)
  end

  describe '.belong_to' do
    it { should belong_to :author }
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
        @featured_content.platforms = []
      end

      it "returns false" do
        @featured_content.valid?.should be_false
      end

      it "sets an error message" do
        @featured_content.valid?
        @featured_content.errors.on(:platforms).should == "can't be blank"
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

    context 'without a tracking offer' do
      before :each do
        @featured_content.tracking_offers.each(&:destroy)
        @featured_content.reload

        Factory(:partner, :id => TAPJOY_PARTNER_ID)
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
          @featured_content.errors.on(:tracking_offer).should == "Please select an offer/app."
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
          @featured_content.errors.on(:tracking_offer).should == "Please select an offer/app."
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


  describe '.featured_contents' do
    before :each do
      @featured_content_for_ipad = Factory(:featured_content, :platforms => %w( ipad android ).to_json)
    end

    context 'when device is ipad' do
      it 'returns featured contents contain ipad in their platforms' do
        FeaturedContent.featured_contents('ipad')[0].should == @featured_content_for_ipad
      end
    end

    context 'when device is iphone' do
      it 'returns featured contents contain ipad in their platforms' do
        FeaturedContent.featured_contents('iphone')[0].should == @featured_content
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
        @featured_content.tracking_offer.send(:geoip_reject?, @geoip_data).should == false
      end

      it 'accepts featured content within country targeting' do
        @geoip_data[:country] = "GL"
        @featured_content.tracking_offer.send(:geoip_reject?, @geoip_data).should == false
      end

      it 'returns featured content within country targeting' do
        featured_contents = FeaturedContent.with_country_targeting(@geoip_data, @device, 'iphone')
        featured_contents.size.should == 1
      end
    end

    context 'when the platform is not match' do
      it 'rejects featured content with different platform' do
        featured_contents = FeaturedContent.with_country_targeting(@geoip_data, @device, 'android')
        featured_contents.size.should == 0
      end
    end

    context 'when there is no country targeting' do
      it 'accepts featured content' do
        @featured_content2.tracking_offer.send(:geoip_reject?, @geoip_data).should == true
      end
    end
  end

  describe '#get_default_icon_url' do
    before :each do
      prefix = "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy"
      icon_id = "dynamic_staff_pick_tool"
      @default_icon_url = "#{prefix}/icons/src/#{icon_id}.jpg"
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

  describe '#has_valid_url?' do
    before :each do
      @featured_content.update_attributes({ :button_url => FeaturedContent::NO_URL })
    end

    it 'returns false' do
      @featured_content.has_valid_url?.should be_false
    end
  end
end
