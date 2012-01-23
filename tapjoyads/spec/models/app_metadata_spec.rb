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
        expect { app_metadata.update_from_store }.to raise_error
      end
    end
    
    context 'when updating app_metadata only from AppStore' do
      it 'updates metadata name' do
        app_metadata = Factory(:app_metadata, :name => 'NotTapDefense', :store_id => "297558390")
        app_metadata.name.should == 'NotTapDefense'
        app_metadata.update_from_store
        app_metadata.name.should == 'TapDefense'
      end
    end
    
    context 'when updating app_metadata and app from AppStore' do
      it 'updates metadata and app name' do
        app_metadata = Factory(:app_metadata, :name => 'NotTapDefense', :store_id => "297558390")
        app = Factory(:app, :name => 'SomeApp')
        app.app_metadatas << app_metadata
        app.save!

        app_metadata.update_from_store
        app.reload

        app_metadata.name.should == 'TapDefense'
        app.name.should == 'TapDefense'
      end
    end
  end
end
