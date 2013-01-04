require 'spec_helper'

describe OfferTriggeredActionsController do
  before :each do
    ApplicationController.stub(:verify_params).and_return(true)
    ApplicationController.stub(:verify_records).and_return(true)
    @generic_offer = FactoryGirl.create(:generic_offer)
    @offer = @generic_offer.primary_offer
    @click = FactoryGirl.create(:click, :offer_id => @offer.id)
    Click.stub(:find).and_return(@click)
    currency = @click.currency
    Currency.stub(:find_in_cache).and_return(currency)
    Offer.stub(:find_in_cache).and_return(@offer)
    @params = {
      :data                  => ObjectEncryptor.encrypt(:data => 'some_data'),
      :id                    => @offer.id,
      :udid                  => @click.udid,
      :publisher_app_id      => @click.currency.app.id,
      :click_key             => @click.key,
      :itunes_link_affiliate => 'itunes',
      :os_version            => '1.0'
    }
  end

  describe "#setup" do
    before :each do
      @offer.stub(:generic_offer_protocol_handler).and_return('test://')
      @offer.stub(:complete_action_url).and_return("some_web_url")
      @offer.stub(:instruction_action_url).and_return("some_instruction_url")
      Offer.stub(:find_in_cache).and_return(@offer)
    end

    it "uses complete_action_url as complete_instruction_url" do
      get(:fb_visit, @params)
      assigns(:complete_instruction_url).should == "some_web_url"
    end

    it "uses instruction_action_url as complete_instruction_url" do
      @offer.instructions = "test instructions"
      @offer.pay_per_click = Offer::PAY_PER_CLICK_TYPES[:ppc_on_instruction]
      get(:fb_visit, @params)
      assigns(:complete_instruction_url).should == "some_instruction_url"
    end

    it "uses complete_action_url as fallback_url" do
      get(:load_app, @params)
      assigns(:fallback_url) == "some_web_url"
    end
  end

  describe '#fb_visit' do
    it 'renders instructions layout' do
      get(:fb_visit, @params)
      response.should render_template('layouts/instructions')
    end
  end

  describe "#load_app" do
    before :each do
      @offer.stub(:complete_action_url).and_return("some_web_url")
      @offer.stub(:instruction_action_url).and_return("some_instruction_url")
      @offer.stub(:generic_offer_protocol_handler).and_return("some_handler_url")
      Offer.stub(:find_in_cache).and_return(@offer)
      GenericOffer.stub(:find_in_cache).and_return(@generic_offer)
    end

    it 'renders load_app' do
      get(:load_app, @params)
      response.should render_template('load_app')
    end

    it 'renders instructions layout' do
      get(:load_app, @params)
      response.should render_template('layouts/instructions')
    end

    it "sets protocol_handler_url from generic offer's protocol_handler" do
      get(:load_app, @params)
      assigns(:protocol_handler_url).should == "some_handler_url"
    end
  end
end
