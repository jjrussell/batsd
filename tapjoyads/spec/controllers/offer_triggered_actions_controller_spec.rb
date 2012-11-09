require 'spec_helper'

describe OfferTriggeredActionsController do
  before :each do
    ApplicationController.stub(:verify_params).and_return(true)
    @app = FactoryGirl.create(:app)
    @offer = @app.primary_offer
    Offer.stub(:find_in_cache).and_return(@offer)
    @currency = FactoryGirl.create(:currency)
    Currency.stub(:find_in_cache).and_return(@currency)
    ApplicationController.stub(:verify_records).and_return(true)
    @offer.stub(:complete_action_url).and_return('some_website_url')
    @action_offer = FactoryGirl.create(:action_offer)
    @params = {
      :data                  => ObjectEncryptor.encrypt(:data => 'some_data'),
      :id                    => @offer.id,
      :udid                  => UUIDTools::UUID.random_create.to_s,
      :publisher_app_id      => @currency.app.id,
      :click_key             => '5',
      :itunes_link_affiliate => 'itunes',
      :os_version            => '1.0'
    }
  end

  describe '#load_app' do
    before :each do
      @offer.stub(:generic_offer_protocol_handler).and_return('test')
    end

    it 'renders load_app' do
      get(:load_app, @params)
      response.should render_template('load_app')
    end
    it 'renders instructions layout' do
      get(:load_app, @params)
      response.should render_template('layouts/instructions')
    end
  end

  describe '#fb_visit' do
    it 'renders instructions layout' do
      get(:fb_visit, @params)
      response.should render_template('layouts/instructions')
    end
  end
end
