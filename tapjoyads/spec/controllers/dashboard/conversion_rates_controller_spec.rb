require 'spec_helper'

describe Dashboard::ConversionRatesController do
  before :each do
    activate_authlogic
    admin = FactoryGirl.create(:admin)
    @partner = FactoryGirl.create(:partner, :id => TAPJOY_PARTNER_ID)
    admin.partners << @partner
    login_as(admin)
    @app = FactoryGirl.create(:app)
    App.stub(:find).and_return(@app)
    @currency = FactoryGirl.create(:currency)
    Currency.stub(:find).and_return(@currency)
    @conversion_rate = FactoryGirl.create(:conversion_rate, :currency_id => @currency.id)
    @conversion_rate2 = FactoryGirl.create(:conversion_rate, :rate => "120", :minimum_offerwall_bid => "100", :currency_id => @currency.id)
    @currency.stub(:conversion_rates).and_return([@conversion_rate, @conversion_rate2])
    Currency.any_instance.stub(:cache).and_return(true)
    @params = {:app_id => @app.id, :currency_id => @currency.id}
  end

  describe '#index' do
    before :each do
      get(:index, @params)
    end
    it 'should respond with 200' do
      should respond_with 200
    end
    it 'should have app instance variable' do
      assigns(:app).should == @app
    end
    it 'should have currency instance variable' do
      assigns(:currency).should == @currency
    end
    it 'should have conversion_rates instance variable' do
      assigns(:conversion_rates).should == [@conversion_rate, @conversion_rate2]
    end
    it 'has an index specific page title' do
      assigns(:page_title).should == I18n.t('text.conversion_rate.index_title')
    end
  end

  describe '#edit' do
    before :each do
      ConversionRate.stub(:find).and_return(@conversion_rate)
      get(:edit, @params.merge(:id => @conversion_rate.id))
    end
    it 'should respond with 200' do
      should respond_with 200
    end
    it 'should have app instance variable' do
      assigns(:app).should == @app
    end
    it 'should have currency instance variable' do
      assigns(:currency).should == @currency
    end
    it 'should have conversion_rates instance variable' do
      assigns(:conversion_rates).should == [@conversion_rate, @conversion_rate2]
    end
    it 'has an edit specific page title' do
      assigns(:page_title).should == I18n.t('text.conversion_rate.edit_title')
    end
    it 'has an conversion_rate instance variable' do
      assigns(:conversion_rate).should == @conversion_rate
    end
  end

  describe '#update' do
    context 'valid update' do
      before :each do
        ConversionRate.stub(:find).and_return(@conversion_rate)
        put(:update, @params.merge(:id => @conversion_rate.id, :conversion_rate => { :rate => "110" }))
      end
      it 'should have a successful flash notice' do
        flash[:notice].should == I18n.t('text.conversion_rate.updated')
      end
      it 'should redirect to index' do
        response.should redirect_to app_currency_conversion_rates_path(:app_id => @app.id, :currency_id => @currency.id)
      end
    end
    context 'invalid update' do
      context 'already taken conversion rate' do
        before :each do
          ConversionRate.stub(:find).and_return(@conversion_rate)
          put(:update, @params.merge(:id => @conversion_rate.id, :conversion_rate => { :rate => "120" }))
        end
        it 'should have a flash notice' do
          flash.now[:error].should == I18n.t('text.conversion_rate.unable_update')
        end
        it 'should render edit layout' do
          response.should render_template('edit')
        end
      end
      context 'an unnecessary conversion rate' do
        before :each do
          ConversionRate.stub(:find).and_return(@conversion_rate)
          put(:update, @params.merge(:id => @conversion_rate.id, :conversion_rate => { :rate => "170" }))
        end
        it 'should have a flash notice' do
          flash.now[:error].should == ConversionRate::OVERLAP_ERROR_MESSAGE
        end
        it 'should render edit layout' do
          response.should render_template('edit')
        end
      end
    end
  end

  describe '#new' do
    before :each do
      @conversion_rate_mock = double(ConversionRate)
      ConversionRate.stub(:new).and_return(@conversion_rate_mock)
      get(:new, @params)
    end
    it 'should respond with 200' do
      should respond_with 200
    end
    it 'should have app instance variable' do
      assigns(:app).should == @app
    end
    it 'should have currency instance variable' do
      assigns(:currency).should == @currency
    end
    it 'should have conversion_rates instance variable' do
      assigns(:conversion_rates).should == [@conversion_rate, @conversion_rate2]
    end
    it 'has a new specific page title' do
      assigns(:page_title).should == I18n.t('text.conversion_rate.new_title')
    end
    it 'has a new conversion rate object' do
      assigns(:conversion_rate).should == @conversion_rate_mock
    end
  end

  describe '#create' do
    context 'valid create' do
      before :each do
        ConversionRate.stub(:save).and_return(true)
        post(:create, @params.merge(:conversion_rate => { :rate => "150", :minimum_offerwall_bid => "300" }))
      end
      it 'should have a successful flash notice' do
        flash[:notice].should == I18n.t('text.conversion_rate.created')
      end
      it 'should redirect to index' do
        response.should redirect_to app_currency_conversion_rates_path(:app_id => @app.id, :currency_id => @currency.id)
      end
    end
    context 'invalid create' do
      context 'already taken conversion rate' do
        before :each do
          ConversionRate.stub(:save).and_return(false)
          post(:create, @params.merge(:conversion_rate => { :rate => "120", :minimum_offerwall_bid => "300"}))
        end
        it 'should have a flash notice' do
          flash.now[:error].should == I18n.t('text.conversion_rate.unable_create')
        end
        it 'should render new layout' do
          response.should render_template('new')
        end
      end
      context 'an unnecessary conversion rate' do
        before :each do
          ConversionRate.stub(:save).and_return(false)
          post(:create, @params.merge(:conversion_rate => { :rate => "101", :minimum_offerwall_bid => "500" }))
        end
        it 'should have a flash notice' do
          flash.now[:error].should == ConversionRate::OVERLAP_ERROR_MESSAGE
        end
        it 'should render new layout' do
          response.should render_template('new')
        end
      end
      context 'a conversion rate with a rate less than a currency\'s conversion rate' do
        before :each do
          ConversionRate.stub(:save).and_return(false)
          post(:create, @params.merge(:conversion_rate => { :rate => "40", :minimum_offerwall_bid => "500" }))
        end
        it 'should have a flash notice' do
          flash.now[:error].should == ConversionRate::CONVERSION_RATE_ERROR_MESSAGE
        end
        it 'should render new layout' do
          response.should render_template('new')
        end
      end
    end
  end

  describe '#destroy' do
    before :each do
      @conversion_rate.should_receive(:destroy)
      ConversionRate.stub(:find).and_return(@conversion_rate)
      delete(:destroy, @params.merge(:id => @conversion_rate.id))
    end
    it 'should have a successfully destroyed flash notice' do
      flash[:notice].should == I18n.t('text.conversion_rate.deleted')
    end
    it 'should redirect to index' do
      response.should redirect_to app_currency_conversion_rates_path(:app_id => @app.id, :currency_id => @currency.id)
    end
  end
end
