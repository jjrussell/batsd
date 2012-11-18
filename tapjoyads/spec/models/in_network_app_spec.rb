require 'spec_helper'

describe InNetworkApp do
  before :each do
    @app = FactoryGirl.create :app
    FactoryGirl.create(:currency, :app_id => @app.id, :callback_url => 'http://foo.com')
    @store_name = 'android.GooglePlay'
    @store_id = 'xyz123'
    @metadata = FactoryGirl.create(:app_metadata,
                                  :store_name => @store_name,
                                  :store_id => @store_id,
                                  :name => 'SomeCoolApp',
                                  :price => 499)
    @app.add_app_metadata(@store_name, @store_id, true)
    FactoryGirl.create(:app_metadata_mapping, :app => @app, :app_metadata => @metadata)

    @metadata.stub(:in_network_app_metadata)

    @ext_pub = ExternalPublisher.new(@app.currencies.first)
  end

  describe '#new' do
    it 'sets app_id, app_name, partner_name and currencies based on external_publisher' do
      in_network_app = InNetworkApp.new(@ext_pub, @metadata)
      in_network_app.app_id.should == @ext_pub.app_id
      in_network_app.app_name.should == @ext_pub.app_name
      in_network_app.partner_name.should == @ext_pub.partner_name
      in_network_app.currencies.should == @ext_pub.currencies
    end

    it 'fetch in_network_app_metadata by calling app_metadata.in_network_app_metadata ' do
      @metadata.should_receive(:in_network_app_metadata).once
      in_network_app = InNetworkApp.new(@ext_pub, @metadata)
    end
  end

  describe '.find_by_store_name_and_store_id' do
    before :each do
      ExternalPublisher.stub(:find_by_app_id).and_return(@ext_pub)
    end

    it 'fetches in_network_app' do
      InNetworkApp.find_by_store_name_and_store_id(@store_name,@store_id).app_id.should == @app.id
    end
  end
end
