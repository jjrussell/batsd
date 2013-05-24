require 'spec_helper'

describe Api::Data::FeaturedContentsController do
  before :each do
    @controller.stub(:verify_signature).and_return(true)
  end

  describe '#load_featured_content' do
    context 'when a device id is not provided' do
      it 'fails' do
        get(:load_featured_content)
        response.response_code.should == 422
        response.body.should include('Missing required params')
      end
    end

    context 'when a device is provided' do
      before :each do
        @device = FactoryGirl.create(:device)
      end

      it 'tries to create the featured content for it' do
        Device.should_receive(:find).and_return(@device)
        FeaturedContent.should_receive(:with_country_targeting).and_return(@featured_content)
        get(:load_featured_content, {:device_id => @device.id})
      end
    end
  end
end
