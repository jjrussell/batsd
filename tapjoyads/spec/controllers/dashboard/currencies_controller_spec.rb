require 'spec_helper'

describe Dashboard::CurrenciesController do
  before :each do
    activate_authlogic
    @user = FactoryGirl.create(:user)
    login_as(@user)
  end
  describe '#show' do
    before :each do
      @app = FactoryGirl.create(:app)
      @currency = FactoryGirl.create(:currency, :app_id => @app.id)
      Currency.stub(:find).and_return(@currency)
      Currency.any_instance.stub(:get_test_device_ids).and_return([@currency.id])
      @params = { :app_id => @app.id, :id => @currency.id }
    end
    context 'tapjoy enabled is true' do
      before :each do
        @currency.tapjoy_enabled = true
        get(:show, @params)
      end
      it 'has an instance variable udids_to_check' do
        assigns(:udids_to_check).should == [[@currency.id, "Never"]]
      end
      it 'has a currency instance variable' do
        assigns(:currency).should == @currency
      end
      it 'has an app instance variable' do
        assigns(:app).should == @app
      end
    end
    context 'tapjoy enabled is false' do
      before :each do
        Currency.any_instance.stub(:tapjoy_enabled?).and_return(false)
        get(:show, @params)
      end
      it 'has an instance variable udids_to_check' do
        assigns(:udids_to_check).should == [[@currency.id, "Never"]]
      end
      it 'has a currency instance variable' do
        assigns(:currency).should == @currency
      end
      it 'has an app instance variable' do
        assigns(:app).should == @app
      end
      it 'has a flash warning' do
        flash.now[:warning].should == "This virtual currency is currently disabled. Please email <a href='mailto:support+enable@tapjoy.com?subject=reenable+currency+ID+#{@currency.id}'>support+enable@tapjoy.com</a> with your app ID to have it enabled. If your application is currently not live, please provide a brief explanation of how you intend to use virtual currency your app."
      end
    end
  end
  describe '#update' do
    before :each do
      @app = FactoryGirl.create(:app)
      @partner = @app.partner
      @currency = FactoryGirl.create(:currency,
                                     :app_id => @app.id,
                                     :partner => @partner)
      @params = { :app_id => @app.id, :id => @currency.id,
                  :currency => JSON.parse(@currency.to_json), :managed_by_tapjoy => false }
    end
    context 'successful update' do
      before :each do
        Currency.any_instance.stub(:safe_update_attributes).and_return(true)
        put(:update, @params)
      end
      it 'has a flash notice' do
        flash[:notice].should == 'Successfully updated.'
      end
    end
    context 'unsuccessful update' do
      before :each do
        Currency.any_instance.stub(:safe_update_attributes).and_return(false)
        put(:update, @params)
      end
      it 'has a flash error' do
        flash.now[:error].should == 'Update unsuccessful.'
      end
      it 'renders show template' do
        response.should render_template('show')
      end
    end
  end
  describe '#create' do
    context 'secondary currency' do
      before :each do
        @currency = FactoryGirl.create(:currency, :tapjoy_enabled => false)
        @params = {
          :terms_of_service => '1',
          :currency => {
            :name => "Super #{@currency.name}",
          }
        }
      end

      it 'is tapjoy disabled' do
        put(:create, @params)
        assigns[:currency].tapjoy_enabled.should be_false
      end
    end
  end
end
