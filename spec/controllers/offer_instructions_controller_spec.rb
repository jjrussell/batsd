require 'spec_helper'

describe OfferInstructionsController do
  describe '#index' do
    render_views
    context 'invalid params' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end

      it 'responds with 400' do
        get(:index)
        should respond_with(400)
      end
    end

    context 'invalid records' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(true)
        ApplicationController.stub(:verify_records).and_return(false)
        offer = FactoryGirl.create(:app).primary_offer
        Offer.stub(:find_in_cache).and_return(offer)
        currency = FactoryGirl.create(:currency)
        Currency.stub(:find_in_cache).and_return(currency)
      end

      it 'responds with 400' do
        get(:index)
        should respond_with(400)
      end
    end

    context 'valid params and records' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(true)
        @app = FactoryGirl.create(:app)
        @offer = @app.primary_offer
        Offer.stub(:find_in_cache).and_return(@offer)
        @currency = FactoryGirl.create(:currency)
        @currency.stub(:active_and_future_sales).and_return({})
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

      it 'responds with 200' do
        get(:index, @params)
        should respond_with(200)
      end

      it 'has the iphone layout' do
       get(:index, @params)
       response.should render_template('layouts/iphone')
      end

      it 'has the intructions layout' do
        @params[:exp] = 'offer_instructions_experiment'
        get(:index, @params)
        response.should render_template('layouts/instructions')
      end

      it 'assigns @complete_instruction_url to a website url' do
       get(:index, @params)
       assigns(:complete_instruction_url).should == 'some_website_url'
      end

      it 'assigns @complete_instruction_url to an instruction action url' do
       @offer.stub(:instruction_action_url).and_return('some_instruction_action_url')
       @offer.pay_per_click = Offer::PAY_PER_CLICK_TYPES[:ppc_on_instruction]
       get(:index, @params)
       assigns(:complete_instruction_url).should == 'some_instruction_action_url'
      end

      it 'assigns @offer to the record found in Offer cache' do
       get(:index, @params)
       assigns(:offer).should == @offer
      end

      it 'assigns @currency to the record found in Currency cache' do
       get(:index, @params)
       assigns(:currency).should == @currency
      end

      context 'protocol handler present' do
        context 'action offer' do
          context 'android device' do
            before :each do
              @offer.item_type = 'ActionOffer'
              @offer.stub(:action_offer_app_id).and_return(@action_offer.app_id)
              @app.protocol_handler = 'test://'
              App.stub(:find_in_cache).and_return(@app)
              visit offer_instructions_path(@params.merge({:device_type => 'android'}))
            end
            it 'should have an input button' do
              page.has_button?("Go to #{@app.name}")
            end
            it 'should respond with 200' do
              response.should be_success
            end
          end
          context 'ios device' do
            before :each do
              @offer.item_type = 'ActionOffer'
              @offer.stub(:action_offer_app_id).and_return(@action_offer.app_id)
              @app.protocol_handler = 'test://'
              App.stub(:find_in_cache).and_return(@app)
              visit offer_instructions_path(@params.merge({:device_type => 'ios'}))
            end
            it 'should not have an input button' do
              page.has_button?("Go to #{@app.name}")
            end
          end
          context 'mispelled android' do
            before :each do
              @offer.item_type = 'ActionOffer'
              @app.protocol_handler = 'test://'
              @offer.stub(:action_offer_app_id).and_return(@action_offer.app_id)
              App.should_receive(:find_in_cache).with(@action_offer.app_id).and_return(@app)
              visit offer_instructions_path(@params.merge({:device_type => 'androidz'}))
            end
            it 'should have an input button' do
              page.has_no_button?("Go to #{@app.name}")
            end
          end
        end
        context 'not action offer' do
          before :each do
            @offer.item_type = 'Coupon'
            @app.protocol_handler = 'test://'
            @offer.should_not_receive(:action_offer_app_id)
            ActionOffer.should_not_receive(:find_in_cache)
            visit offer_instructions_path(@params.merge({:device_type => 'android'}))
          end
          it 'should not have an input button' do
            page.has_no_button?("Go to #{@app.name}")
          end
        end
      end
      context 'protocol handler blank' do
        before :each do
          @offer.item_type = 'ActionOffer'
          @app.protocol_handler = nil
          @offer.stub(:action_offer_app_id).and_return(@action_offer.app_id)
          App.should_receive(:find_in_cache).with(@action_offer.app_id).and_return(@app)
          visit offer_instructions_path(@params.merge({:device_type => 'android'}))
        end
        it 'should not have an input button' do
          page.has_no_button?("Go to #{@app.name}")
        end
      end
    end
  end

  describe '#app_not_installed' do
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
        App.stub(:find_in_cache).with(@app.id).and_return(@app)
        @params = {
          :data                  => ObjectEncryptor.encrypt(:data => 'some_data'),
          :id                    => @offer.id,
          :udid                  => UUIDTools::UUID.random_create.to_s,
          :publisher_app_id      => @currency.app.id,
          :click_key             => '5',
          :itunes_link_affiliate => 'itunes',
          :os_version            => '1.0',
          :action_app_id         => @app.id
        }
      end

    it 'renders crap' do
      @params[:exp] = 'test'
      get(:app_not_installed, @params)
      response.should render_template('layouts/iphone')
    end
  end
end
