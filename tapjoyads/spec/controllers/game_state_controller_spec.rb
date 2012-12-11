require 'spec_helper'

describe GameStateController do
  describe '#load' do
    context 'invalid params' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end
      it 'responds with 400' do
        get(:load)
        should respond_with(400)
      end
    end

    context 'valid params' do
      before :each do
        @currency = double(Currency, :initial_balance => 100, :app_id => '12345')
        @params = {
          :app_id            => @currency.app_id,
          :tapjoy_device_id  => '67890',
          :publisher_user_id => '2813308004',
          :version           => '1'
        }
        @game_state = FactoryGirl.create(:game_state)
        GameState.stub(:new).and_return(@game_state)
        Currency.stub(:find_in_cache).and_return(@currency)
        @point_purchases = FactoryGirl.create(:point_purchases)
        PointPurchases.stub(:new).and_return(@point_purchases)
      end
      it 'sets @game_state' do
        get(:load, @params)
        assigns(:game_state).should == @game_state
      end

      context 'game_state.version and params[:version] are ==' do
        it 'sets @up_to_date to true' do
          get(:load, @params)
          assigns(:up_to_date).should == true
        end
      end

      context 'game_state.version and params[:version] are !=' do
        it 'sets @up_to_date to false' do
          @params[:version] = '2'
          get(:load, @params)
          assigns(:up_to_date).should == false
        end
      end

      it 'sets @point_purchases' do
        get(:load, @params)
        assigns(:point_purchases).should == @point_purchases
      end

      it 'sets @currency' do
        get(:load, @params)
        assigns(:currency).should == @currency
      end

      it 'responds with 200' do
        get(:load, @params)
        should respond_with(200)
      end
    end

    context 'missing params[:publisher_user_id]' do
      before :each do
        @currency = double(Currency, :initial_balance => 100, :app_id => '12345')
        @params = {
          :app_id            => @currency.app_id,
          :tapjoy_device_id  => '67890',
          :version           => '1'
        }
        Currency.stub(:find_in_cache).and_return(@currency)
        @game_state_mapping = FactoryGirl.create(:game_state_mapping)
        GameStateMapping.stub(:new).and_return(@game_state_mapping)
      end

      it 'generates a new params[:publisher_user_id] from GameStateMapping class and assigns to point_purchases key' do
        get(:load, @params)
        assigns(:point_purchases).key.should == "#{@game_state_mapping.publisher_user_id}.#{@params[:app_id]}"
      end

      it 'generates a new params[:publisher_user_id] from GameStateMapping class and assigns to game_state key' do
        get(:load, @params)
        assigns(:game_state).key.should == "#{@params[:app_id]}.#{@game_state_mapping.publisher_user_id}"
      end
    end
  end

  describe '#save' do
    context 'invalid params' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end
      it 'responds with 400' do
        get(:save)
        should respond_with(400)
      end
    end

    context 'valid params' do
      before :each do
        @currency = double(Currency, :initial_balance => 100, :app_id => '12345')
        @params = {
          :app_id            => @currency.app_id,
          :tapjoy_device_id  => '67890',
          :publisher_user_id => '2813308004',
          :version           => '1',
          :data              => { 'date' => 'some_data' },
          :game_state_points => '50'
        }
        Currency.stub(:find_in_cache).and_return(@currency)
        @game_state = FactoryGirl.create(:game_state)
        GameState.stub(:new).and_return(@game_state)
        GameState.stub(:save).and_return(true)
      end

      it 'sets @game_state.data' do
        get(:save, @params)
        assigns(:game_state).data.should == @params[:data]
      end

      it 'sets @game_state.version' do
        get(:save, @params)
        assigns(:game_state).version.should == 2
      end

      it 'sets @game_state.tapjoy_points' do
        get(:save, @params)
        assigns(:game_state).tapjoy_points.should == @params[:game_state_points].to_i
      end

      it 'responds with 200' do
        get(:save, @params)
        should respond_with(200)
      end
    end
  end
end
