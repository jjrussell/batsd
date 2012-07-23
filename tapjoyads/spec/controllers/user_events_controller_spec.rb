require 'spec_helper'

describe UserEventsController do

  before(:each) do
    @app = FactoryGirl.create(:app)
    @device = FactoryGirl.create(:device)
    @app.cache
    # Use an IAP event, since it's got additional required params
    @geoip_data = {
      :country => "USA",
      :primary_country => "USA",
    }
    @ip_address = '10.0.0.1'
    @user_agent = 'not_a_real_user'
    @options = {
      :event_type_id => 1,
      :app_id => @app.id,
      :udid => @device.id,
      :ue => {
        :quantity => FactoryGirl.generate(:integer),
        :price => FactoryGirl.generate(:integer).to_f,
        :name => FactoryGirl.generate(:name),
        :currency_id => "Currency #{FactoryGirl.generate(:name)}",
      },
      :verifier => 'should_recompute_me_with_each_variable_change',
    }
  end

  describe '#create' do

    context 'with an invalid app_id' do
      before(:each) do
        @options[:app_id] = "completely f'd app_id"
      end

      it 'responds with a 400 and an invalid app id error' do
        post 'create', @options
        response.status.should == 400
      end
    end

    context 'without any device identifiers' do
      before(:each) do
        @options.delete(:udid)
      end

      it 'responds with a 400 and a no device error' do
        post 'create', @options
        response.status.should == 400
      end
    end
  end
end
