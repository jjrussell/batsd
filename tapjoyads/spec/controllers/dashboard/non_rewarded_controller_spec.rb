require 'spec_helper'

describe Dashboard::NonRewardedController do
  before :each do
    activate_authlogic
    @user = FactoryGirl.create(:user)
    login_as(@user)
  end
  describe '#index' do
    context 'currency not set (no app non-rewarded)' do
      before :each do
        @app = FactoryGirl.create(:app)
        @partner = @app.partner
        App.any_instance.stub(:partner).and_return(@partner)
        App.any_instance.stub(:non_rewarded).and_return([])
        @currency = FactoryGirl.create(:currency,
                                       :conversion_rate => 0,
                                       :callback_url => Currency::NO_CALLBACK_URL,
                                       :name => Currency::NON_REWARDED_NAME,
                                       :app_id => @app.id,
                                       :partner => @partner)
        @currency.tapjoy_enabled = false
        App.any_instance.stub(:build_non_rewarded).and_return(@currency)
        @params = { :app_id => @app.id }
        get(:index, @params)
      end
      it 'has a currency object that is non-rewarded' do
        assigns(:currency).should == @currency
      end
      it 'has enabled instance variable' do
        assigns(:enabled).should be_false
      end
      it 'has app instance variable' do
        assigns(:app).should == @app
      end
      it 'has a partner instance variable' do
        assigns(:partner).should == @partner
      end
      it 'responds with 200' do
        should respond_with 200
      end
      it 'renders index' do
        response.should render_template('index')
      end
    end
    context 'app already has non rewarded currency' do
      before :each do
        @app = FactoryGirl.create(:app)
        @partner = @app.partner
        App.any_instance.stub(:partner).and_return(@partner)
        @currency = FactoryGirl.create(:currency,
                                       :conversion_rate => 0,
                                       :callback_url => Currency::NO_CALLBACK_URL,
                                       :name => Currency::NON_REWARDED_NAME,
                                       :app_id => @app.id,
                                       :partner => @partner)
        @currency.tapjoy_enabled = false
        App.any_instance.stub(:non_rewarded).and_return(@currency)
        @params = { :app_id => @app.id }
        get(:index, @params)
      end
      it 'has a currency object that is non-rewarded' do
        assigns(:currency).should == @currency
      end
      it 'has enabled instance variable' do
        assigns(:enabled).should be_false
      end
      it 'has app instance variable' do
        assigns(:app).should == @app
      end
      it 'has a partner instance variable' do
        assigns(:partner).should == @partner
      end
      it 'responds with 200' do
        should respond_with 200
      end
      it 'renders index' do
        response.should render_template('index')
      end
    end
  end
  describe '#toggle' do
    context 'valid terms of service' do
      context 'partner already accepted tos' do
        before :each do
          @app = FactoryGirl.create(:app)
          @partner = @app.partner
          @partner.accepted_publisher_tos = true
          App.any_instance.stub(:partner).and_return(@partner)
          @currency = FactoryGirl.create(:currency,
                                         :conversion_rate => 0,
                                         :callback_url => Currency::NO_CALLBACK_URL,
                                         :name => Currency::NON_REWARDED_NAME,
                                         :app_id => @app.id,
                                         :partner => @partner)
          @currency.tapjoy_enabled = false
          App.any_instance.stub(:non_rewarded).and_return(@currency)
          @params = { :app_id => @app.id }
          post(:toggle, @params)
        end
        it 'renders index' do
          response.should render_template('index')
        end
        it 'has an enabled instance variable' do
          assigns(:enabled).should be_true
        end
        it 'has a flash notice' do
          flash[:notice].should == "Non-rewarded has been enabled."
        end
      end
      context 'partner hasn\'t yet accepted tos' do
        context 'did not click the accept tos check box' do
          before :each do
            @app = FactoryGirl.create(:app)
            @partner = @app.partner
            @partner.accepted_publisher_tos = false
            App.any_instance.stub(:partner).and_return(@partner)
            @currency = FactoryGirl.create(:currency,
                                           :conversion_rate => 0,
                                           :callback_url => Currency::NO_CALLBACK_URL,
                                           :name => Currency::NON_REWARDED_NAME,
                                           :app_id => @app.id,
                                           :partner => @partner)
            @currency.tapjoy_enabled = false
            App.any_instance.stub(:non_rewarded).and_return(@currency)
            @params = { :app_id => @app.id, :terms_of_service => '0' }
            post(:toggle, @params)
          end
          it 'has a flash error' do
            flash[:error].should == 'You must accept the terms of service to set up non-rewarded.'
          end
          it 'renders index' do
            response.should render_template('index')
          end
        end
        context 'clicked the accept tos check box' do
           before :each do
            @app = FactoryGirl.create(:app)
            @partner = @app.partner
            @partner.accepted_publisher_tos = false
            App.any_instance.stub(:partner).and_return(@partner)
            @currency = FactoryGirl.create(:currency,
                                           :conversion_rate => 0,
                                           :callback_url => Currency::NO_CALLBACK_URL,
                                           :name => Currency::NON_REWARDED_NAME,
                                           :app_id => @app.id,
                                           :partner => @partner)
            @currency.tapjoy_enabled = false
            App.any_instance.stub(:non_rewarded).and_return(@currency)
            @params = { :app_id => @app.id, :terms_of_service => '1' }
            post(:toggle, @params)
          end
          it 'has a flash error' do
            flash[:notice].should == "Non-rewarded has been enabled."
          end
          it 'renders index' do
            response.should render_template('index')
          end
          it 'has an enabled instance variable' do
            assigns(:enabled).should be_true
          end
          it 'sets partners accepted publisher tos to true' do
            @partner.accepted_publisher_tos.should be_true
          end
        end
        context 'currency not saved' do
           before :each do
            @app = FactoryGirl.create(:app)
            @partner = @app.partner
            @partner.accepted_publisher_tos = false
            App.any_instance.stub(:partner).and_return(@partner)
            @currency = FactoryGirl.build(:currency,
                                          :conversion_rate => 0,
                                          :callback_url => Currency::NO_CALLBACK_URL,
                                          :name => Currency::NON_REWARDED_NAME,
                                          :app_id => @app.id)
            @currency.tapjoy_enabled = false
            @currency.partner = nil
            App.any_instance.stub(:non_rewarded).and_return(@currency)
            @params = { :app_id => @app.id, :terms_of_service => '1' }
            post(:toggle, @params)
          end
          it 'has a flash error' do
            flash.now[:error].should == "Could not enable non-rewarded."
          end
          it 'renders index' do
            response.should render_template('index')
          end
        end
      end
    end
  end
end
