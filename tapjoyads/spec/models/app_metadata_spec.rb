require 'spec_helper'

describe AppMetadata do
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

    context 'when updating app_metadata only from AppStore' do
      it 'updates metadata name' do
        app_metadata = FactoryGirl.create(:app_metadata, :name => 'MyApp', :store_id => "abcdefg")

        app_metadata.should_receive(:save_screenshots)
        AppStore.should_receive(:fetch_app_by_id).and_return({:title => 'SomeOtherApp', :price => 0, :categories => []})
        app_metadata.update_from_store

        app_metadata.name.should == 'SomeOtherApp'
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
      @app_metadata.should_receive(:save)
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
      @app_metadata.should_receive(:save)

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
end
