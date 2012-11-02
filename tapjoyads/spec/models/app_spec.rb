require 'spec_helper'

describe App do

  subject { FactoryGirl.create(:app) }

  # Check associations
  it { should have_many :currencies }
  it { should have_many :non_rewarded_featured_offers }
  it { should have_many :non_rewarded_offers }
  it { should have_many :offers }
  it { should have_many :publisher_conversions }
  it { should have_many :rewarded_featured_offers }
  it { should have_many :app_metadatas }
  it { should have_many :reengagement_offers }
  it { should have_one :rating_offer }
  it { should have_one :primary_currency }
  it { should have_one :primary_offer }
  it { should have_one :primary_app_metadata }
  it { should have_one :primary_app_metadata_mapping }
  it { should belong_to :partner }
  it { should have_one :non_rewarded }

  # Check validations
  it { should validate_presence_of :partner }
  it { should validate_presence_of :name }

  context 'An App' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    it 'does not list North Korea as a possible appstore country' do
      App::APPSTORE_COUNTRIES_OPTIONS.map(&:last).should_not include('KP')
    end
  end

  describe '#can_have_new_currency?' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    context 'without currencies' do
      it 'returns true ' do
        @app.should be_can_have_new_currency
      end
    end

    context 'without currency that has special callback' do
      it 'returns true' do
        FactoryGirl.create(:currency, :app_id => @app.id, :callback_url => 'http://foo.com')
        FactoryGirl.create(:currency, :app_id => @app.id, :callback_url => 'http://bar.com')
        @app.should be_can_have_new_currency
      end
    end

    context 'with currency that has special callback' do
      it 'returns false' do
        special_url = Currency::SPECIAL_CALLBACK_URLS.sample
        FactoryGirl.create(:currency, :app_id => @app.id, :callback_url => special_url)
        @app.should_not be_can_have_new_currency
      end
    end
  end

  describe 'notifications' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    it 'should not be enabled' do
      @app.notifications_enabled?.should == false
    end
  end

  describe '#launch_url' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    context 'with a protocol_handler' do
      it 'returns the protocol handler URL' do
        url = 'app_url://some/data'
        @app.protocol_handler = url
        @app.launch_url.should == url
      end
    end
  end

  describe '#test_offer' do
    before :each do
      @app = FactoryGirl.create(:app)
      @test_offer = @app.test_offer
    end

    it 'creates test Offer with the same ID' do
      @test_offer.id.should == @app.id
      @test_offer.item_id.should == @app.id
      @test_offer.item_type.should == 'TestOffer'
    end
  end

  describe '#test_video_offer' do
    before :each do
      @app = FactoryGirl.create(:app)
      @test_video_offer = @app.test_video_offer
      @test_video_offer_primary_offer = @test_video_offer.primary_offer
    end

    it 'creates test VideoOffer with ID "test_video"' do
      @test_video_offer.id.should == 'test_video'
      @test_video_offer.partner_id.should == @app.partner_id
    end

    it 'creates test VideoOffer with primary offer ID "test_video"' do
      @test_video_offer_primary_offer.id.should == 'test_video'
      @test_video_offer_primary_offer.item_id.should == 'test_video'
      @test_video_offer_primary_offer.item_type.should == 'TestVideoOffer'
    end
  end

  context 'that is not live' do
    describe '#add_app_metadata' do
      before :each do
        @app = FactoryGirl.create(:non_live_app, :platform => 'android')
      end

      it "returns primary metadata" do
        @app.app_metadatas.count.should == 0
        metadata = @app.add_app_metadata('android.GooglePlay', 'xyz123', true)
        @app.reload
        @app.app_metadatas.count.should == 1
        @app.primary_app_metadata.should == metadata
      end

      it 'updates primary offer from added primary metadata' do
        @app.primary_offer.app_metadata.should be_nil
        metadata = FactoryGirl.create(:app_metadata, :store_name => 'android.GooglePlay', :store_id => 'xyz123', :name => 'SomeCoolApp', :price => 499)
        @app.add_app_metadata('android.GooglePlay', 'xyz123', true)
        @app.reload
        @app.primary_app_metadata.should_not be_nil
        @app.primary_offer.app_metadata.should == @app.primary_app_metadata
        @app.primary_offer.name.should == metadata.name
        @app.primary_offer.price.should == metadata.price
      end

      context 'when adding non-primary metadata' do
        it "fails" do
          metadata = @app.add_app_metadata('android.GooglePlay', 'xyz123', false)
          @app.reload
          @app.app_metadatas.count.should == 0
          metadata.should be_nil
        end
      end

      context 'using invalid params' do
        it "fails" do
          metadata = @app.add_app_metadata('Invalid Store', 'invalid_app', false)
          @app.reload
          @app.app_metadatas.count.should == 0
          metadata.should be_nil
        end
      end
    end
  end

  describe '#add_app_metadata' do
    before :each do
      @app = FactoryGirl.create(:app)
      @app.primary_app_metadata.update_attributes(:store_name => 'android.GooglePlay')
      @app.reload
    end

    context 'using existing store name' do
      it "fails" do
        metadata = @app.add_app_metadata('android.GooglePlay', 'xyz123', false)
        @app.reload
        @app.app_metadatas.count.should == 1
        metadata.should be_nil
      end
    end

    context 'for another primary metadata' do
      it "fails" do
        metadata = @app.add_app_metadata('android.GFan', 'xyz123', true)
        @app.reload
        @app.app_metadatas.count.should == 1
        metadata.should be_nil
      end
    end

    it "returns added metadata" do
      metadata = @app.add_app_metadata('android.GFan', 'xyz123', false)
      @app.reload
      @app.app_metadatas.count.should == 2
      @app.app_metadatas.find(metadata.id).should be_present
    end

    it 'creates a rewarded offer' do
      metadata = AppMetadata.find_by_store_name_and_store_id('android.GFan', 'xyz123')
      metadata.should be_nil
      metadata = @app.add_app_metadata('android.GFan', 'xyz123', false)
      @app.reload
      metadata.offers.count.should == 1
      offer = metadata.offers.first
      offer.third_party_data.should == metadata.store_id
      offer.app.should == @app
    end

    context 'when adding metadata for existing store_name/store_id combo' do
      before :each do
        @existing_metadata = FactoryGirl.create(:app_metadata, :store_name => 'android.GFan', :store_id => 'some_app')
      end

      it 'adds mapping with existing matching metadata' do
        metadata = @app.add_app_metadata('android.GFan', 'some_app', false)
        metadata.should == @existing_metadata
      end
    end
  end

  describe '#update_app_metadata' do
    before :each do
      @app = FactoryGirl.create(:app)
      @app.primary_app_metadata.update_attributes(:store_name => 'android.GooglePlay')
      @app.reload
    end

    context 'when updating non-existent metadata' do
      it "fails" do
        lambda {metadata = @app.update_app_metadata('android.GFan', 'xyz123')}.should raise_error
      end
    end

    context 'when updating with new store id' do
      before :each do
        @old_metadata = @app.primary_app_metadata
        @old_offer    = @app.primary_offer
        @metadata     = @app.update_app_metadata('android.GooglePlay', 'xyz123')
        @app.reload
      end

      it "removes previous app_metadata and attaches new one" do
        @app.app_metadatas.count.should == 1
        @app.primary_app_metadata.should_not == @old_metadata
        @app.primary_app_metadata.should == @metadata
        @app.primary_app_metadata.store_id.should == 'xyz123'
      end

      it "updates existing offer from new metadata" do
        @app.offers.count.should == 1
        @app.primary_offer.should == @old_offer
        @app.primary_offer.app_metadata.should == @metadata
        @app.primary_offer.third_party_data.should == 'xyz123'
      end

      context 'then updating the new metadata' do
        it "updates the offer" do
          AppStore.should_receive(:fetch_app_by_id).and_return({ :title => 'SomeMeaninglessApp', :price => 200, :categories => [] })
          @metadata.update_from_store
          @app.primary_offer.reload
          @app.primary_offer.name.should == 'SomeMeaninglessApp'
        end
      end

      context 'then updating the old metadata' do
        it "doesn't update the offer" do
          AppStore.should_receive(:fetch_app_by_id).and_return({ :title => 'SomeMeaninglessApp', :price => 200, :categories => [] })
          @old_metadata.update_from_store
          @app.primary_offer.reload
          @app.primary_offer.name.should_not == 'SomeMeaninglessApp'
        end
      end
    end

    context 'when updating with same store id' do
      before :each do
        @from_add     = @app.add_app_metadata('android.GFan', 'xyz123', false)
        @old_offer    = @app.offers.find_by_app_metadata_id(@from_add.id)
        @from_update  = @app.update_app_metadata('android.GFan', 'xyz123')
        @distribution = @app.app_metadata_mappings.find_by_app_metadata_id(@from_update.id)
        @app.reload
      end

      it "returns same app_metadata" do
        @app.app_metadatas.count.should == 2
        @from_update.should == @from_add
      end

      it "doesn't change existing offer" do
        @app.offers.find_by_app_metadata_id(@from_update.id).should == @old_offer
        @distribution.primary_offer.should == @old_offer
        @old_offer.third_party_data.should == 'xyz123'
      end

      context 'then updating the app metadata' do
        it "updates offer as well" do
          @distribution.primary_offer.third_party_data.should == 'xyz123'
          @from_update.update_attributes(:name => 'MyApp', :price => 250)
          @distribution.primary_offer.name.should == 'MyApp'
          @distribution.primary_offer.price.should == 250
        end
      end
    end
  end

  describe '#remove_app_metadata' do
    before :each do
      @app = FactoryGirl.create(:app)
      @app.primary_app_metadata.update_attributes(:store_name => 'android.GooglePlay')
      @metadata = @app.add_app_metadata('android.GFan', 'xyz123', false)
      @app.reload
    end

    context 'when removing non-existent metadata' do
      it "fails and returns false" do
        metadata = AppMetadata.new(:store_name => 'iphone.AppStore', :store_id => 'xyz123')
        status = @app.remove_app_metadata(metadata)
        @app.reload
        @app.app_metadatas.count.should == 2
        status.should be_false
      end
    end

    context 'when removing primary metadata' do
      it "fails and returns false" do
        status = @app.remove_app_metadata(@app.primary_app_metadata)
        @app.reload
        @app.app_metadatas.count.should == 2
        status.should be_false
      end
    end

    context 'when removing non-primary metadata' do
      before :each do
        @status = @app.remove_app_metadata(@metadata)
        @app.reload
      end

      it "removes metadata mapping from app" do
        @app.app_metadatas.count.should == 1
        @app.app_metadatas.include?(@metadata).should be_false
        @status.should be_true
      end

      it "does not delete app_metadata" do
        AppMetadata.find(@metadata.id).should_not be_nil
      end
    end

    context 'when removing non-primary metadata with secondary offers' do
      before :each do
        @distribution = @app.app_metadata_mappings.find_by_app_metadata_id(@metadata.id)
        @featured_offer = @distribution.primary_offer.create_rewarded_featured_clone
        @non_rewarded_offer = @distribution.primary_offer.create_non_rewarded_clone
        @offer_ids = @distribution.offers.map { |offer| offer.id }
        @status = @app.remove_app_metadata(@metadata)
        @app.reload
      end

      it "removes all associated offers" do
        @app.offers.count.should == 1
        @app.offers.map {|o| o.id }.include?(@offer_ids).should be_false
      end
    end
  end

  context 'with Offers' do
    before :each do
      @app = FactoryGirl.create(:app)
      @offer = @app.primary_offer
    end

    it "updates its offers' bids when its price changes" do
      @app.primary_app_metadata.update_attributes({:price => 400})
      @offer.reload
      @offer.bid.should equal(200)
      @offer.price.should equal(400)
    end

    it "doesn't update offer's device types unless store id changes" do
      @offer.device_types.should == Offer::APPLE_DEVICES.to_json
      @offer.update_attributes({:device_types => Offer::ANDROID_DEVICES})
      @app.primary_app_metadata.update_attributes({:age_rating => 2})
      @offer.reload
      @offer.age_rating.should == 2
      @offer.device_types.should == Offer::ANDROID_DEVICES.to_json
    end

    it "updates offer's device types if store id changes" do
      @offer.device_types.should == Offer::APPLE_DEVICES.to_json
      @offer.update_attributes({:device_types => Offer::ANDROID_DEVICES})
      @offer.device_types.should == Offer::ANDROID_DEVICES.to_json
      @app.update_app_metadata('iphone.AppStore', '7654321')
      @app.save!
      @offer.reload
      @offer.device_types.should == Offer::APPLE_DEVICES.to_json
    end
  end

  context 'with Action Offers' do
    before :each do
      @action_offer = FactoryGirl.create(:action_offer)
      @app = @action_offer.app
      @action_offer.partner = @app.partner
      @action_offer.save
    end

    it 'updates action offer hidden field' do
      @app.update_attributes({:hidden => true})
      @action_offer.reload
      @action_offer.should be_hidden
      @action_offer.primary_offer.should_not be_tapjoy_enabled
    end

    it "updates action offer bids when its price changes" do
      @app.primary_app_metadata.update_attributes({:price => 400})
      @action_offer.reload
      @action_offer.primary_offer.bid.should equal(200)
      @action_offer.primary_offer.price.should equal(400)
    end

    it 'does not update action offer bids if it has a prerequisite offer' do
      @action_offer.prerequisite_offer = @app.primary_offer
      @action_offer.save
      offer = @action_offer.primary_offer
      @app.primary_app_metadata.update_attributes({:price => 400})
      offer.reload
      offer.bid.should equal(10)
    end
  end

  context 'with a Non-Rewarded Featured Offer' do
    before :each do
      @app = FactoryGirl.create :app
      @new_offer = @app.primary_offer.create_non_rewarded_featured_clone
      @app.reload
    end

    it 'has non-rewarded featured associations' do
      @app.primary_non_rewarded_featured_offer.should == @new_offer
      @app.non_rewarded_featured_offers.size.should equal(1)
      @app.non_rewarded_featured_offers.should include(@new_offer)
    end

    it 'does not have rewarded featured associations' do
      @app.primary_rewarded_featured_offer.should be_nil
      @app.rewarded_featured_offers.should be_empty
    end

    it 'does not have non-rewarded associations' do
      @app.primary_non_rewarded_offer.should be_nil
      @app.non_rewarded_offers.should be_empty
    end
  end

  context 'with a Rewarded Featured Offer' do
    before :each do
      @app = FactoryGirl.create :app
      @new_offer = @app.primary_offer.create_rewarded_featured_clone
      @app.reload
    end

    it 'has rewarded featured associations' do
      @app.primary_rewarded_featured_offer.should == @new_offer
      @app.rewarded_featured_offers.size.should equal(1)
      @app.rewarded_featured_offers.should include(@new_offer)
    end

    it 'does not have non-rewarded featured associations' do
      @app.primary_non_rewarded_featured_offer.should be_nil
      @app.non_rewarded_featured_offers.should be_empty
    end

    it 'does not have non-rewarded associations' do
      @app.primary_non_rewarded_offer.should be_nil
      @app.non_rewarded_offers.should be_empty
    end
  end

  context 'with a Non-Rewarded Offer' do
    before :each do
      @app = FactoryGirl.create :app
      @new_offer = @app.primary_offer.create_non_rewarded_clone
      @app.reload
    end

    it 'has non-rewarded associations' do
      @app.primary_non_rewarded_offer.should == @new_offer
      @app.non_rewarded_offers.size.should equal(1)
      @app.non_rewarded_offers.should include(@new_offer)
    end

    it 'does not have rewarded featured associations' do
      @app.primary_rewarded_featured_offer.should be_nil
      @app.rewarded_featured_offers.should be_empty
    end

    it 'does not have non-rewarded featured associations' do
      @app.primary_non_rewarded_featured_offer.should be_nil
      @app.non_rewarded_featured_offers.should be_empty
    end
  end

  describe '#reengagement_campaign' do
    context 'without any reengagement offers' do
      before :each do
        @app = FactoryGirl.create(:app)
      end

      it 'returns an empty list' do
        @app.reengagement_campaign.should be_empty
      end
    end

    context 'with a full reengagement campaign' do
      before :each do
        currency = FactoryGirl.create(:currency)
        @app = currency.app
        5.times do
          offer = @app.build_reengagement_offer(
            :currency => currency,
            :reward_value => 3,
            :instructions => "do some stuff"
          )
          puts offer.errors.full_messages unless offer.save
        end
        @app.reload
      end

      it 'returns the entire reengagement campaign as an array' do
        @app.reengagement_campaign.length.should == 5
      end
    end
  end

  describe '#enable_reengagement_campaign!' do
    context 'without any reengagement offers' do
      before :each do
        @app = FactoryGirl.create(:app)
      end

      it 'does not change self.reengagement_campaign_enabled' do
        before = @app.reengagement_campaign_enabled?
        @app.enable_reengagement_campaign!
        after = @app.reengagement_campaign_enabled?
        before.should == after
      end
    end

    context 'with a full reengagement campaign' do
      before :each do
        currency = FactoryGirl.create(:currency)
        @app = currency.app
        5.times do
          @app.build_reengagement_offer(
            :currency => currency,
            :reward_value => 3,
            :instructions => "do some stuff"
          ).save
        end
        @app.enable_reengagement_campaign!
        @app.reload
      end

      it 'enables the reengagement campaign' do
        @app.reengagement_campaign_enabled.should == true
      end

      it 'caches the entire reengagement offer array' do
        ReengagementOffer.find_all_in_cache_by_app_id(@app.id).should == @app.reengagement_campaign
      end
    end
  end

  describe '#disable_reengagement_campaign!' do
    context 'without any reengagement offers' do
      before :each do
        @app = FactoryGirl.create(:app)
      end

      it 'does not change self.reengagement_campaign_enabled' do
        before = @app.reengagement_campaign_enabled?
        @app.disable_reengagement_campaign!
        after = @app.reengagement_campaign_enabled?
        before.should == after
      end
    end

    context 'with a full reengagement campaign' do
      before :each do
        currency = FactoryGirl.create(:currency)
        @app = currency.app
        5.times do
          @app.build_reengagement_offer(
            :currency => currency,
            :reward_value => 3,
            :instructions => "do some stuff"
          ).save
        end
        @app.enable_reengagement_campaign!
        @app.disable_reengagement_campaign!
        @app.reload
      end

      it 'disables the reengagement campaign' do
        @app.reengagement_campaign_enabled.should == false
      end

      it 'uncaches the entire reengagement offer array' do
        Mc.get("mysql.reengagement_offers.#{@app.id}.#{@acts_as_cacheable_version}").should be_nil
      end
    end
  end

  describe '#build_reengagement_offer' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    it 'builds a new reengagement offer' do
      reengagement_offers = @app.reengagement_campaign
      new_reengagement_offer = @app.build_reengagement_offer
      reengagement_offers.should_not be_include(new_reengagement_offer) and @app.reengagement_campaign.should be_include(new_reengagement_offer)
    end
  end

  describe '#reengagement_campaign_from_cache' do
    context 'without any reengagement offers' do
      before :each do
        @app = FactoryGirl.create(:app)
      end

      it 'returns an empty list' do
        Mc.get("mysql.reengagement_offers.#{@app.id}.#{@acts_as_cacheable_version}").should be_nil
      end
    end

    context 'with a full reengagement campaign' do
      before :each do
        currency = FactoryGirl.create(:currency)
        @app = currency.app
        5.times do
          @app.build_reengagement_offer(
            :currency => currency,
            :reward_value => 3,
            :instructions => "do some stuff"
          ).save
        end
        @app.enable_reengagement_campaign!
        @app.reload
      end

      it 'returns the entire reengagement campaign as a list' do
        @app.reengagement_campaign.should == @app.reengagement_campaign_from_cache
      end
    end
  end


  describe '#dashboard_app_url' do
    include Rails.application.routes.url_helpers
    before :each do
      @app = FactoryGirl.create :app
    end

    it 'matches URL for Rails app_url helper' do
      @app.dashboard_app_url.should == "#{URI.parse(DASHBOARD_URL).scheme}://#{URI.parse(DASHBOARD_URL).host}/apps/#{@app.id}"
    end
  end


  describe '#os_versions' do
    before :each do
      @app = FactoryGirl.create :app
    end

    context 'android' do
      before :each do
        @app.platform = 'android'
      end

      it 'has available versions' do
        (@app.os_versions - %w( 1.5 1.6 2.0 2.1 2.2 2.3 3.0 3.1 3.2 4.0 4.1)).should be_empty
      end
    end

    context 'iphone' do
      before :each do
        @app.platform = 'iphone'
      end

      it 'has available versions' do
        (@app.os_versions - %w( 2.0 2.1 2.2 3.0 3.1 3.2 4.0 4.1 4.2 4.3 5.0 5.1 6.0 )).should be_empty
      end
    end

    context 'windows' do
      before :each do
        @app.platform = 'windows'
      end

      it 'has available versions' do
        (@app.os_versions - %w( 7.0 )).should be_empty
      end
    end
  end

  describe '#primary_rewarded_featured_offer' do
    before :each do
      @app = FactoryGirl.create :non_live_app
      @offer = @app.primary_offer.create_rewarded_featured_clone
    end

    context 'with non-live app' do
      it 'returns primary rewarded featured offer' do
        @app.primary_rewarded_featured_offer.should == @offer
      end
    end

    context 'with live app' do
      it 'returns primary rewarded featured offer' do
        @app.add_app_metadata('android.GooglePlay', 'xyz123', true)
        @app.reload
        app_metadata = @app.add_app_metadata('android.GFan', 'abcdefg', false)
        @app.reload
        other_offer = @app.app_metadata_mappings.where(:is_primary => false).first.primary_offer.create_rewarded_featured_clone
        @app.primary_rewarded_featured_offer.should === @offer
        @app.primary_rewarded_featured_offer.should_not === other_offer
      end
    end
  end

  describe '#primary_non_rewarded_featured_offer' do
    before :each do
      @app = FactoryGirl.create :non_live_app
      @offer = @app.primary_offer.create_non_rewarded_featured_clone
    end

    context 'with non-live app' do
      it 'returns primary non-rewarded featured offer' do
        @app.primary_non_rewarded_featured_offer.should == @offer
      end
    end

    context 'with live app' do
      it 'returns primary non-rewarded featured offer' do
        @app.add_app_metadata('android.GooglePlay', 'xyz123', true)
        @app.reload
        app_metadata = @app.add_app_metadata('android.GFan', 'abcdefg', false)
        @app.reload
        other_offer = @app.app_metadata_mappings.where(:is_primary => false).first.primary_offer.create_non_rewarded_featured_clone
        @app.primary_non_rewarded_featured_offer.should === @offer
        @app.primary_non_rewarded_featured_offer.should_not === other_offer
      end
    end
  end

  describe '#primary_non_rewarded_offer' do
    before :each do
      @app = FactoryGirl.create :non_live_app
      @offer = @app.primary_offer.create_non_rewarded_clone
    end

    context 'with non-live app' do
      it 'returns primary non-rewarded offer' do
        @app.primary_non_rewarded_offer.should == @offer
      end
    end

    context 'with live app' do
      it 'returns primary non-rewarded offer' do
        @app.add_app_metadata('android.GooglePlay', 'xyz123', true)
        @app.reload
        app_metadata = @app.add_app_metadata('android.GFan', 'abcdefg', false)
        @app.reload
        other_offer = @app.app_metadata_mappings.where(:is_primary => false).first.primary_offer.create_non_rewarded_clone
        @app.primary_non_rewarded_offer.should === @offer
        @app.primary_non_rewarded_offer.should_not === other_offer
      end
    end
  end

  describe '#videos_cache_on?' do
    before :each do
      @app = FactoryGirl.create :app
    end

    context 'when the connection type is wifi' do
      before :each do
        @connection = 'wifi'
      end

      it 'should not be true if videos are disabled' do
        @app.update_attributes(:videos_enabled => false)
        @app.should_not be_videos_cache_on(@connection)
      end

      it 'should be true if caching over wifi is enabled' do
        @app.update_attributes(:videos_cache_wifi => true)
        @app.should be_videos_cache_on(@connection)
      end

      it 'should not be true if caching over wifi is disabled' do
        @app.update_attributes(:videos_cache_wifi => false)
        @app.should_not be_videos_cache_on(@connection)
      end
    end

    context 'when the connection type is mobile' do
      before :each do
        @connection = 'mobile'
      end

      it 'should not be true if videos are disabled' do
        @app.update_attributes(:videos_enabled => false)
        @app.should_not be_videos_cache_on(@connection)
      end

      it 'should be true if caching over 3g is enabled' do
        @app.update_attributes(:videos_cache_3g => true)
        @app.should be_videos_cache_on(@connection)
      end

      it 'should not be true if caching over 3g is disabled' do
        @app.update_attributes(:videos_cache_3g => false)
        @app.should_not be_videos_cache_on(@connection)
      end
    end

    context 'when the connection type is other' do
      before :each do
        @connection = 'other'
      end

      it 'should not be true if videos are disabled' do
        @app.update_attributes(:videos_enabled => false)
        @app.should_not be_videos_cache_on(@connection)
      end

      it 'should not be true' do
        @app.should_not be_videos_cache_on(@connection)
      end
    end
  end

  describe '#videos_stream_on?' do
    before :each do
      @app = FactoryGirl.create :app
    end

    context 'when the connection type is wifi' do
      before :each do
        @connection = 'wifi'
      end

      it 'should not be true if videos are disabled' do
        @app.update_attributes(:videos_enabled => false)
        @app.should_not be_videos_stream_on(@connection)
      end

      it 'should be true if videos are enabled' do
        @app.should be_videos_stream_on(@connection)
      end
    end

    context 'when the connection type is mobile' do
      before :each do
        @connection = 'mobile'
      end

      it 'should not be true if videos are disabled' do
        @app.update_attributes(:videos_enabled => false)
        @app.should_not be_videos_stream_on(@connection)
      end

      it 'should be true if streaming over 3g is enabled' do
        @app.update_attributes(:videos_stream_3g => true)
        @app.should be_videos_stream_on(@connection)
      end

      it 'should not be true if streaming over 3g is disabled' do
        @app.update_attributes(:videos_stream_3g => false)
        @app.should_not be_videos_stream_on(@connection)
      end
    end

    context 'when the connection type is other' do
      before :each do
        @connection = 'other'
      end

      it 'should not be true' do
        @app.should_not be_videos_stream_on(@connection)
      end
    end
  end

  describe '#build_non_rewarded' do
    before :each do
      @app = FactoryGirl.create(:app)
      @partner = @app.partner
      @currency = FactoryGirl.create(:currency,
                                     :conversion_rate => 0,
                                     :callback_url => Currency::NO_CALLBACK_URL,
                                     :name => Currency::NON_REWARDED_NAME,
                                     :app_id => @app.id,
                                     :partner => @partner)
      Currency.stub(:new).and_return(@currency)
    end
    it 'returns the currency object' do
      @app.build_non_rewarded.should == @currency
    end
  end

  describe '#associated_offers' do
    subject { FactoryGirl.create(:app) }

    it 'excludes the primary offer' do
      subject.associated_offers.should_not include subject.primary_offer
    end

    context 'by default' do #no params...
      context 'given secondary offers' do
        let!(:secondary_offers) { 3.times.map { o = subject.primary_offer.clone; o.save!; o } }

        it 'includes all secondary offers' do
          secondary_offers.all? { |offer| subject.associated_offers.include?(offer) }.should be_true
        end
      end
    end

    context 'called with a key-value list of properties' do
      let(:properties) { {:foo => :bar} }

      context 'given an app with secondary offers' do
        let(:offer_matching_properties) do
          o = subject.primary_offer.clone
          o.stub(:foo).and_return(:bar)
          o
        end

        let(:offer_not_matching_properties) do
          o = subject.primary_offer.clone
          o.stub(:foo).and_return(nil)
          o
        end

        before(:each) { subject.stub(:offers).and_return [ offer_matching_properties, offer_not_matching_properties ] }

        it 'excludes secondary offers not matching those properties' do
          subject.associated_offers(properties).should_not include offer_not_matching_properties
        end

        it 'includes secondary offers matching those properties' do
          subject.associated_offers(properties).should include offer_matching_properties
        end
      end
    end
  end
end
