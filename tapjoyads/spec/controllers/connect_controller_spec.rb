require 'spec_helper'

describe ConnectController do
  render_views

  describe '#index' do
    context 'with required parameters' do
      before :each do
        app = FactoryGirl.create(:app)
        offer = app.primary_offer
        device = FactoryGirl.create(:device)
        device.sdkless_clicks = { offer.third_party_data => { 'click_time' => (Time.zone.now - 1.hour).to_i, 'item_id' => offer.id }}

        @params = { :app_id => 'test_app',
                    :udid   => 'test_device' }

        Device.stub(:new).and_return(device)
      end

      it "returns an XML response" do
        get(:index, @params)
        response.content_type.should == 'application/xml'
      end

      it "returns a successful response" do
        get(:index, @params)
        response.body.should include('Success')
      end

      context 'without SDK-less parameters' do
        it "doesn't return SDK-less click package names" do
          get(:index, @params)
          response.body.should_not include('PackageNames')
        end
      end

      context 'with SDK-less parameters' do
        before :each do
          controller.stub(:sdkless_supported?).and_return(true)
        end

        it "returns SDK-less click package names" do
          get(:index, @params)
          response.body.should include('PackageNames')
        end
      end
    end

    context 'without required parameters' do
      it "returns an error code" do
        get(:index)
        response.response_code.should == 400
      end
    end
  end
end
