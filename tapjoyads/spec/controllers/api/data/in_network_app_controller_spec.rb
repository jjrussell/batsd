require 'spec_helper'

describe Api::Data::InNetworkAppController do
  before :each do
    InNetworkApp.stub(:find_by_store_name_and_store_id).and_return(mock('in_network_app'))
  end

  describe '#search' do
    before :each do
      @controller.stub(:verify_signature).and_return(true)
    end

    it 'looks up the object' do
      InNetworkApp.should_receive(:find_by_store_name_and_store_id).with('store_name','store_id')
      get(:search, :store_name => 'store_name', :store_id => 'store_id')
    end
  end
end
