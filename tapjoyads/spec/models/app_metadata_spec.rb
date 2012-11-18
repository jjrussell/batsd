require 'spec_helper'

describe AppMetadata do

  subject { FactoryGirl.create(:app_metadata) }

  # Check associations
  it { should have_many :apps }
  it { should have_many :app_reviews }

  # Check validations
  it { should validate_presence_of :store_name }
  it { should validate_presence_of :store_id }
  it { should validate_numericality_of :thumbs_up }
  it { should validate_numericality_of :thumbs_down }

  describe '#update_from_store' do
    context 'when AppStore returns no data' do
      it 'raises an error' do
        app_metadata = FactoryGirl.create(:app_metadata)
        AppStore.should_receive(:fetch_app_by_id).and_raise(Exception.new "Invalid response from app store.")
        expect { app_metadata.update_from_store }.to raise_error
      end
    end

    context 'when updating non-primary app_metadata from AppStore' do
      it 'updates metadata name' do
        app = FactoryGirl.create(:app, :name => 'MyApp')
        app_metadata = app.add_app_metadata('android.GFan', 'abcdefg', false)
        app_metadata.update_attributes(:name => 'MyApp2')

        AppStore.should_receive(:fetch_app_by_id).and_return({:title => 'SomeOtherApp', :price => 0, :categories => []})
        app_metadata.update_from_store

        app_metadata.name.should == 'SomeOtherApp'
        app.name.should == 'MyApp'
      end
    end

    context 'when updating app_metadata and app from AppStore' do
      it 'updates metadata and app name' do
        app = FactoryGirl.create(:app, :name => 'MyApp')
        app.primary_app_metadata.update_attributes({ :name => 'MyApp', :store_id => 'abcdefg' })

        AppStore.should_receive(:fetch_app_by_id).and_return({:title => 'SomeOtherApp', :price => 0, :categories => []})
        app.primary_app_metadata.update_from_store
        app.reload

        app.primary_app_metadata.name.should == 'SomeOtherApp'
        app.name.should == 'SomeOtherApp'
      end
    end

    context 'when more than one app has same app metadata' do
      before :each do
        @app1 = FactoryGirl.create(:app)
        @app1.app_metadata_mappings.destroy_all
        @app1.save!
        @metadata = @app1.add_app_metadata('android.GooglePlay', 'xyz123', true)
      end

      context 'and all are primary' do
        before :each do
          @app2 = FactoryGirl.create(:app)
          @app2.app_metadata_mappings.destroy_all
          @app2.save!
          @app2.add_app_metadata('android.GooglePlay', 'xyz123', true)
          @app2.reload

          @app1.app_metadatas.count.should == 1
          @app2.app_metadatas.count.should == 1
          @app2.primary_app_metadata.should == @metadata
        end

        it 'updates all apps' do
          AppStore.should_receive(:fetch_app_by_id).and_return({:title => 'SomeApp', :price => 0, :categories => []})
          @metadata.update_from_store
          @app1.reload
          @app1.name.should == 'SomeApp'
          @app2.reload
          @app2.name.should == 'SomeApp'
        end
      end

      context 'and only one is primary' do
        before :each do
          @app2 = FactoryGirl.create(:app)
          @app2.add_app_metadata('android.GooglePlay', 'xyz123', false)
          @app2.reload

          @app1.app_metadatas.count.should == 1
          @app2.app_metadatas.count.should == 2
          @app2.primary_app_metadata.should_not == @metadata
        end

        it 'updates only the app for which it is the primary app metadata' do
          old_name = @app2.name
          AppStore.should_receive(:fetch_app_by_id).and_return({:title => 'SomeApp', :price => 0, :categories => []})
          @metadata.update_from_store
          @app1.reload
          @app1.name.should == 'SomeApp'
          @app2.reload
          @app2.name.should_not == 'SomeApp'
          @app2.name.should == old_name
        end
      end
    end
  end

  describe "#save_screenshots" do
    before :each do
      @app_metadata = FactoryGirl.create(:app_metadata)
      @screenshot_urls = ['url1', 'url2', 'url3']

      @app_metadata.should_receive(:download_blob).with('url1').and_return('blob1')
      @app_metadata.should_receive(:download_blob).with('url2').and_return('blob2')
      @app_metadata.should_receive(:download_blob).with('url3').and_return('blob3')

      @app_metadata.should_receive(:upload_screenshot).exactly(3).times
      @app_metadata.should_receive(:delete_screenshots).with(Set.new)
      @app_metadata.should_receive(:save!)
    end

    it 'saves the screenshots' do
      @app_metadata.save_screenshots(@screenshot_urls)
    end

    it 'only uploads/deletes the changed screenshots' do
      @app_metadata.save_screenshots(@screenshot_urls)
      @screenshot_urls = ['url1', 'url2', 'url4']

      @app_metadata.should_receive(:download_blob).with('url1').and_return('blob1')
      @app_metadata.should_receive(:download_blob).with('url2').and_return('blob5')
      @app_metadata.should_receive(:download_blob).with('url4').and_return('blob4')
      @app_metadata.should_receive(:upload_screenshot).with('blob5', @app_metadata.hashed_blob(Digest::MD5.hexdigest('blob5')))
      @app_metadata.should_receive(:upload_screenshot).with('blob4', @app_metadata.hashed_blob(Digest::MD5.hexdigest('blob4')))
      @app_metadata.should_receive(:delete_screenshots).with(Set.new([@app_metadata.hashed_blob(Digest::MD5.hexdigest('blob2')),
                                                             @app_metadata.hashed_blob(Digest::MD5.hexdigest('blob3'))]))
      @app_metadata.should_receive(:save!)

      @app_metadata.save_screenshots(@screenshot_urls)
    end
  end

  describe '#total_thumbs_count' do
    before :each do
      @app_metadata = FactoryGirl.create(:app_metadata)
      @app_metadata.thumbs_up   = 4
      @app_metadata.thumbs_down = 4
    end

    it 'equals 8' do
      @app_metadata.total_thumbs_count.should == 8
    end
  end

  describe '#positive_thumbs_percentage' do
    before :each do
      @app_metadata = FactoryGirl.create(:app_metadata)
      @app_metadata.thumbs_up   = 4
      @app_metadata.thumbs_down = 4
    end

    it 'equals 50' do
      @app_metadata.positive_thumbs_percentage.should == 50
    end
  end

  context 'when updated' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    context 'including name' do
      it "updates associated offer's name" do
        @app.primary_app_metadata.update_attributes(:name => 'MyFavoriteApp')
        @app.primary_offer.name.should == 'MyFavoriteApp'
      end

      context 'but offer name was customized' do
        it "doesn't update offer name" do
          @app.primary_offer.update_attributes(:name => 'SpecialCustomName')
          @app.primary_app_metadata.update_attributes(:name => 'MyFavoriteApp')
          @app.primary_offer.name.should == 'SpecialCustomName'
        end
      end
    end

    context 'including age rating' do
      it "updates associated offer's age rating" do
        @app.primary_app_metadata.update_attributes(:age_rating => 5)
        @app.primary_offer.age_rating.should == 5
      end
    end

    context 'including price' do
      it "updates associated offer's price" do
        @app.primary_app_metadata.update_attributes(:price => 500)
        @app.primary_offer.price.should == 500
      end

      context 'and current offer bid is below min bid' do
        it 'sets offer bid to min bid' do
          old_bid = @app.primary_offer.bid
          @app.primary_app_metadata.update_attributes(:price => 500)
          @app.primary_offer.reload
          @app.primary_offer.bid.should_not == old_bid
          @app.primary_offer.bid.should == @app.primary_offer.min_bid
        end
      end

      context 'and current offer bid is above max bid' do
        it 'sets offer bid to max bid' do
          @app.primary_app_metadata.update_attributes(:price => 500000)
          @app.primary_offer.reload.update_attributes(:bid => 100000)
          @app.primary_offer.bid.should == 100000
          @app.primary_app_metadata.update_attributes(:price => 500)
          @app.primary_offer.reload
          @app.primary_offer.bid.should_not == 100000
          @app.primary_offer.bid.should == @app.primary_offer.max_bid
        end
      end
    end

    context 'including file_size_bytes' do
      context 'where size forces wifi only download' do
        it "updates associated offer's wifi_only setting" do
          @app.primary_app_metadata.wifi_required?.should be_false
          @app.primary_app_metadata.update_attributes(:file_size_bytes => App::PLATFORM_DETAILS[@app.platform][:cell_download_limit_bytes] + 100)
          @app.primary_offer.wifi_only.should be_true
        end
      end

      context 'where size does not force wifi only download' do
        it "doesn't update associated offer's wifi_only setting" do
          @app.primary_app_metadata.update_attributes(:file_size_bytes => 1000)
          @app.primary_offer.wifi_only.should be_false
        end
      end
    end

    context 'but device_types was customized' do
      it "doesn't update offer's device type" do
        @app.primary_offer.device_types.should == @app.primary_app_metadata.get_offer_device_types.to_json
        @app.primary_offer.device_types = %w(android iphone ipad).to_json
        @app.primary_offer.save!
        @app.primary_app_metadata.update_attributes({ :name => 'MyFavoriteApp', :price => 199 })
        @app.primary_offer.reload
        @app.primary_offer.device_types.should_not == @app.primary_app_metadata.get_offer_device_types.to_json
        @app.primary_offer.device_types.should == %w(android iphone ipad).to_json
      end
    end

    context 'and associated with multiple offers' do
      before :each do
        @app.primary_offer.create_rewarded_featured_clone
        @app.primary_offer.create_non_rewarded_featured_clone
        @app.primary_offer.create_non_rewarded_clone
        @app.offers.count.should == 4
      end

      it "updates all associated offers" do
        @app.primary_app_metadata.update_attributes(:name => 'MyFavoriteApp')
        @app.app_metadata_mappings.count.should == 1
        distribution = @app.app_metadata_mappings.first
        distribution.primary_offer.name.should == 'MyFavoriteApp'
        distribution.primary_rewarded_featured_offer.name.should == 'MyFavoriteApp'
        distribution.primary_non_rewarded_featured_offer.name.should == 'MyFavoriteApp'
        distribution.primary_non_rewarded_offer.name.should == 'MyFavoriteApp'
      end
    end
  end

  describe '#in_network_app_metadata' do
    before :each do
      @app_metadata = FactoryGirl.create(:app_metadata, :screenshots => ["a", "b"])
    end

    it 'sets name, description, developer, price, age_rating, user_rating, and categories based on app_metadata' do
      in_network_app_metadata = @app_metadata.in_network_app_metadata
      in_network_app_metadata[:name].should == @app_metadata.name
      in_network_app_metadata[:description].should == @app_metadata.description
      in_network_app_metadata[:developer].should == @app_metadata.developer
      in_network_app_metadata[:price].should == @app_metadata.price
      in_network_app_metadata[:age_rating].should == @app_metadata.age_rating
      in_network_app_metadata[:user_rating].should == @app_metadata.user_rating
      in_network_app_metadata[:categories].should == @app_metadata.categories
    end

    it 'gets icon_url from IconHandler.get_icon_url' do
      IconHandler.should_receive(:get_icon_url).once
      @app_metadata.in_network_app_metadata
    end

    it 'assembles screenshot urls based on app_metadata.screenshots' do
      @app_metadata.in_network_app_metadata
      screenshot_urls = [
        "https://s3.amazonaws.com/#{BucketNames::APP_SCREENSHOTS}/app_store/original/a",
        "https://s3.amazonaws.com/#{BucketNames::APP_SCREENSHOTS}/app_store/original/b"
      ]
      @app_metadata.in_network_app_metadata[:screenshots].should == screenshot_urls
    end
  end
end
