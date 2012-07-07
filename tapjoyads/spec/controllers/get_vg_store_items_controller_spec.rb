require 'spec_helper'

describe GetVgStoreItemsController do
  describe '#all' do
    context 'invalid params([:app_id, :udid, :publisher_user_id])' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end

      it 'responds with 400 error' do
        get(:all)
        should respond_with(400)
      end
    end

    context 'invalid app_id not found in Currency' do
      before :each do
        app = FactoryGirl.create(:app)
        ApplicationController.stub(:verify_params).and_return(true)
        Currency.stub(:find_in_cache).and_return(nil)
        @params = {
            :app_id             => app.id,
            :udid               => 'stuff',
            :publisher_user_id  => 'me!'
        }
      end

      it 'renders template error for invalid app_id and assigns an error message' do
        get(:all, @params)
        should render_template('layouts/error')
        assigns(:error_message).should == 'There is no currency for this app. Please create one to use the virtual goods API.'
      end
    end

    context 'valid params' do
      before :each do
        app = FactoryGirl.create(:app)
        @params = {
            :app_id             => app.id,
            :udid               => 'stuff',
            :publisher_user_id  => 'me!'
        }
        currency = FactoryGirl.create(:currency, :id => app.id)
        vg = FactoryGirl.create(:virtual_good)
        ApplicationController.stub(:verify_params).and_return(false)
        ApplicationController.stub(:ip_address).and_return('192.168.1.1')
        ApplicationController.stub(:geoip_location).and_return({ :country => 'United States' })
        Mc.stub(:get_and_put).and_return()
        Currency.stub(:find_in_cache).and_return(currency)
        PointPurchases.stub(:after_initialize).and_return(50)
        @point_purchases = FactoryGirl.create(:point_purchases)
        PointPurchases.stub(:new).and_return(@point_purchases, :key => "#{@params[:publisher_user_id]}.#{@params[:app_id]}")
        VirtualGood.stub(:select).and_return(vg)
        PointPurchases.stub(:get_virtual_good_quantity).and_return(4)
      end

      it 'successfully gets the #all action' do
        get(:all, @params)
        assigns(:point_purchases).key.should == @point_purchases.key
        response.should be_success
      end
    end
  end

  describe '#purchased' do
    context 'invalid params([:app_id, :udid, :publisher_user_id])' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end

      it 'responds with 400 error' do
        get(:purchased)
        should respond_with(400)
      end
    end

    context 'invalid app_id in Currency' do
      before :each do
        app = FactoryGirl.create(:app)
        ApplicationController.stub(:verify_params).and_return(true)
        Currency.stub(:find_in_cache).and_return(nil)
        @params = {
            :app_id             => app.id,
            :udid               => 'stuff',
            :publisher_user_id  => 'me!'
        }
      end

      it 'renders template error for invalid app_id and assigns an error message' do
        get(:purchased, @params)
        should render_template('layouts/error')
        assigns(:error_message).should == 'There is no currency for this app. Please create one to use the virtual goods API.'
      end
    end

    context 'valid params' do
      before :each do
        app = FactoryGirl.create(:app)
        @params = {
            :app_id             => app.id,
            :udid               => 'stuff',
            :publisher_user_id  => 'me!'
        }
        currency = FactoryGirl.create(:currency, :id => app.id)
        vg = FactoryGirl.create(:virtual_good)
        ApplicationController.stub(:verify_params).and_return(false)
        ApplicationController.stub(:ip_address).and_return('192.168.1.1')
        ApplicationController.stub(:geoip_location).and_return({ :country => 'United States' })
        Currency.stub(:find_in_cache).and_return(currency)
        PointPurchases.stub(:after_initialize).and_return(50)
        @point_purchases = FactoryGirl.create(:point_purchases)
        PointPurchases.stub(:new).and_return(@point_purchases, :key => "#{@params[:publisher_user_id]}.#{@params[:app_id]}")
        VirtualGood.stub(:select).and_return(vg)
        PointPurchases.stub(:get_virtual_good_quantity).and_return(4)
      end

      it 'successfully gets the #purchased action' do
        get(:purchased, @params)
        assigns(:point_purchases).key.should == @point_purchases.key
        response.should be_success
      end
    end
  end

  describe '#user_account' do
    context 'invalid params([:app_id, :udid, :publisher_user_id])' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end

      it 'responds with 400 error' do
        get(:user_account)
        should respond_with(400)
      end
    end

    context 'invalid app_id in Currency' do
      before :each do
        app = FactoryGirl.create(:app)
        ApplicationController.stub(:verify_params).and_return(true)
        Currency.stub(:find_in_cache).and_return(nil)
        @params = {
            :app_id             => app.id,
            :udid               => 'stuff',
            :publisher_user_id  => 'me!'
        }
      end

      it 'renders template error for invalid app_id and assigns an error message' do
        get(:user_account, @params)
        should render_template('layouts/error')
        assigns(:error_message).should == 'There is no currency for this app. Please create one to use the virtual goods API.'
      end
    end

    context 'valid params' do
      before :each do
        app = FactoryGirl.create(:app)
        @params = {
            :app_id             => app.id,
            :udid               => 'stuff',
            :publisher_user_id  => 'me!'
        }
        currency = FactoryGirl.create(:currency, :id => app.id)
        vg = FactoryGirl.create(:virtual_good)
        ApplicationController.stub(:verify_params).and_return(false)
        ApplicationController.stub(:ip_address).and_return('192.168.1.1')
        ApplicationController.stub(:geoip_location).and_return({ :country => 'United States' })
        Currency.stub(:find_in_cache).and_return(currency)
        @point_purchases = FactoryGirl.create(:point_purchases, :key => "#{@params[:app_id]}.test", :points => 42)
        PointPurchases.stub(:after_initialize).and_return(50)
        PointPurchases.stub(:new).and_return(@point_purchases)
        VirtualGood.stub(:select).and_return(vg)
        PointPurchases.stub(:get_virtual_good_quantity).and_return(4)
      end

      it 'successfully gets the #user_account action' do
        get(:user_account, @params)
        controller.instance_eval{ @point_purchases.points }.should == 42
        controller.instance_eval{ @point_purchases.get_udid }.should == @params[:app_id]
        controller.instance_eval{ @currency.name }.should == 'TAPJOY_BUCKS'
        response.should be_success
      end
    end
  end
end
