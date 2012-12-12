require 'spec_helper'

describe AdshownController do
  describe '#index' do
    context 'invalid params([:app_id, :udid, :campaign_id])' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end

      it 'responds with 400 error' do
        get(:index)
        should respond_with(400)
      end
    end

    context 'valid params' do
      before :each do
        @params = {
            :app_id             => 'test_id',
            :udid               => 'stuff',
            :campaign_id        => 'me!'
        }
        ApplicationController.stub(:verify_params).and_return(true)
        ApplicationController.stub(:ip_address).and_return('192.168.1.1')
        ApplicationController.stub(:geoip_location).and_return({ :country => 'United States' })
      end

      it 'successfully gets the #index action and returns 200' do
        get(:index, @params)
        should respond_with(200)
      end

      it 'renders the success template' do
        get(:index, @params)
        should render_template('layouts/success')
      end
    end
  end
end
