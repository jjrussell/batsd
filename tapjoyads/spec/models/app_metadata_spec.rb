require 'spec_helper'

describe AppMetadata do
  # Check associations
  it { should have_many :apps }

  # Check validations
  it { should validate_presence_of :store_name }
  it { should validate_presence_of :store_id }
  
  describe '#update_from_store' do
    context 'when AppStore returns no data' do
      it 'raises an error' do
        app_metadata = Factory(:app_metadata)
        AppStore.expects(:fetch_app_by_id).raises(Exception, "Invalid response from app store.")
        expect { app_metadata.update_from_store }.to raise_error
      end
    end
    
    context 'when updating app_metadata only from AppStore' do
      it 'updates metadata name' do
        app_metadata = Factory(:app_metadata, :name => 'MyApp', :store_id => "abcdefg")

        AppStore.expects(:fetch_app_by_id).returns({:title => 'SomeOtherApp', :price => 0, :categories => []})
        app_metadata.update_from_store
        
        app_metadata.name.should == 'SomeOtherApp'
      end
    end
    
    context 'when updating app_metadata and app from AppStore' do
      it 'updates metadata and app name' do
        app_metadata = Factory(:app_metadata, :name => 'MyApp', :store_id => "abcdefg")
        app = Factory(:app, :name => 'MyApp')
        app.app_metadatas << app_metadata
        app.save!

        AppStore.expects(:fetch_app_by_id).returns({:title => 'SomeOtherApp', :price => 0, :categories => []})
        app_metadata.update_from_store
        app.reload

        app_metadata.name.should == 'SomeOtherApp'
        app.name.should == 'SomeOtherApp'
      end
    end
  end
end
