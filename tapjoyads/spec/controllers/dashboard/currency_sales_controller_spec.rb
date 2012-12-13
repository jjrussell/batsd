require 'spec_helper'

describe Dashboard::CurrencySalesController do
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
    @currency_sale = FactoryGirl.create(:currency_sale, :currency_id => @currency.id)
    @params = {:app_id => @app.id, :currency_id => @currency.id}
  end

  describe '#index' do
    before :each do
      @currency.stub_chain(:currency_sales, :active).and_return([@currency_sale])
      @currency.stub_chain(:currency_sales, :past, :paginate).and_return([])
      @currency.stub_chain(:currency_sales, :future, :paginate).and_return([])
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
    it 'should have active_currency_sales instance variable' do
      assigns(:active_currency_sales).should == [@currency_sale]
    end
    it 'should have past_currency_sales instance variable' do
      assigns(:past_currency_sales).should == []
    end
    it 'should have future_currency_sales instance variable' do
      assigns(:future_currency_sales).should == []
    end
    it 'has an index specific page title' do
      assigns(:page_title).should == "#{@currency.name} Currency Sales"
    end
  end

  describe '#edit' do
    before :each do
      @currency.stub_chain(:currency_sales, :active).and_return([@currency_sale])
      @currency.stub_chain(:currency_sales, :past, :paginate).and_return([])
      @currency.stub_chain(:currency_sales, :future, :paginate).and_return([])
      CurrencySale.stub(:find).and_return(@currency_sale)
      get(:edit, @params.merge(:id => @currency_sale.id))
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
    it 'should have active_currency_sales instance variable' do
      assigns(:active_currency_sales).should == [@currency_sale]
    end
    it 'should have past_currency_sales instance variable' do
      assigns(:past_currency_sales).should == []
    end
    it 'should have future_currency_sales instance variable' do
      assigns(:future_currency_sales).should == []
    end
    it 'has an edit specific page title' do
      assigns(:page_title).should == "Edit Currency Sale"
    end
    it 'has an currency_sale instance variable' do
      assigns(:currency_sale).should == @currency_sale
    end
  end

  describe '#update' do
    before :each do
      @currency_sale2 = FactoryGirl.create(:currency_sale, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 4.days)
      @currency.stub(:currency_sales).and_return([@currency_sale, @currency_sale2])
      @currency.stub_chain(:currency_sales, :active).and_return([@currency_sale])
      @currency.stub_chain(:currency_sales, :past, :paginate).and_return([])
      @currency.stub_chain(:currency_sales, :future, :paginate).and_return([@currency_sale2])
    end
    context 'valid update' do
      before :each do
        update_params = { :currency_sale => {
                      :start_time => @currency_sale.start_time.to_s,
                      :end_time   => @currency_sale.end_time.to_s,
                      :multiplier => '3' },
                    :id => @currency_sale.id
        }
        CurrencySale.stub(:find).and_return(@currency_sale)
        Currency.any_instance.stub(:cache).and_return(true)
        put(:update, @params.merge(update_params))
      end
      it 'should have a successful flash notice' do
        flash[:notice].should == "Successfully updated the currency sale"
      end
      it 'should redirect to index' do
        response.should redirect_to app_currency_currency_sales_path(:app_id => @app.id, :currency_id => @currency.id)
      end
    end
    context 'invalid update' do
      before :each do
        CurrencySale.stub(:find).and_return(@currency_sale)
        update_params = { :currency_sale => {
                      :start_time => (Time.zone.now + 6.days).to_s,
                      :end_time   => (Time.zone.now + 5.days).to_s,
                      :multiplier => @currency_sale.multiplier },
                    :id => @currency_sale.id
        }
        put(:update, @params.merge(update_params))
      end
      it 'should have a flash error' do
        flash.now[:error].should == "Unable to update currency sale"
      end
      it 'should render edit layout' do
        response.should render_template('edit')
      end
    end
  end

  describe '#new' do
    before :each do
      @currency_sale2 = FactoryGirl.create(:currency_sale, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 4.days)
      @currency.stub_chain(:currency_sales, :active).and_return([@currency_sale])
      @currency.stub_chain(:currency_sales, :past, :paginate).and_return([])
      @currency.stub_chain(:currency_sales, :future, :paginate).and_return([@currency_sale2])
      @currency_sale_mock = double(CurrencySale)
      CurrencySale.stub(:new).and_return(@currency_sale_mock)
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
    it 'should have active_currency_sales instance variable' do
      assigns(:active_currency_sales).should == [@currency_sale]
    end
    it 'should have past_currency_sales instance variable' do
      assigns(:past_currency_sales).should == []
    end
    it 'should have future_currency_sales instance variable' do
      assigns(:future_currency_sales).should == [@currency_sale2]
    end
    it 'has a new specific page title' do
      assigns(:page_title).should == "New Currency Sale"
    end
    it 'has a new conversion rate object' do
      assigns(:currency_sale).should == @currency_sale_mock
    end
  end

  describe '#create' do
    before :each do
      @currency_sale2 = FactoryGirl.create(:currency_sale, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 4.days)
      @currency.stub(:currency_sales).and_return([@currency_sale, @currency_sale2])
      @currency.stub_chain(:currency_sales, :active).and_return([@currency_sale])
      @currency.stub_chain(:currency_sales, :past, :paginate).and_return([])
      @currency.stub_chain(:currency_sales, :future, :paginate).and_return([@currency_sale2])
    end
    context 'valid create' do
      before :each do
        CurrencySale.any_instance.stub(:save).and_return(true)
        create_params = { :currency_sale => {
                      :start_time => Time.zone.now + 10.days,
                      :end_time   => Time.zone.now + 11.days,
                      :multiplier => '3' }
        }
        post(:create, @params.merge(create_params))
      end
      it "should set the currency" do
        assigns(:currency_sale).currency.should == @currency
      end
      it 'should have a successful flash notice' do
        flash[:notice].should == "Successfully created currency sale"
      end
      it 'should redirect to index' do
        response.should redirect_to app_currency_currency_sales_path(:app_id => @app.id, :currency_id => @currency.id)
      end
    end
    context 'invalid create' do
      let(:error_message) { "test message" }
      let(:do_request)    { post(:create, @params.merge(create_params)) }
      let(:create_params) { { :currency_sale => {
                      :start_time => Time.zone.now + 6.days,
                      :end_time   => Time.zone.now + 5.days,
                      :multiplier => '3' }
      }}
      let(:currency_sale) do
        CurrencySale.new.tap do |sale|
          sale.errors.add :base, error_message
          sale.stub!(:save).and_return(false)
        end
      end

      before(:each) do
        # Ensure instance is created before .new is stubbed
        currency_sale && CurrencySale.stub!(:new).and_return(currency_sale)
      end

      it "should instantiate currency sale with params" do
        CurrencySale.should_receive(:new).with(create_params[:currency_sale].stringify_keys)
        do_request
      end

      it "should save the sale" do
        currency_sale.should_receive(:save).and_return(false)
        do_request
      end

      it 'should have a flash error' do
        do_request; flash.now[:error].should == error_message
      end
      it 'should render edit layout' do
        do_request; response.should render_template('new')
      end
    end
  end

  describe '#destroy' do
    before :each do
      @currency_sale.should_receive(:destroy)
      CurrencySale.stub(:find).and_return(@currency_sale)
      delete(:destroy, @params.merge(:id => @currency_sale.id))
    end
    it 'should have a successfully destroyed flash notice' do
      flash[:notice].should == "Successfully removed the currency sale"
    end
    it 'should redirect to index' do
      response.should redirect_to app_currency_currency_sales_path(:app_id => @app.id, :currency_id => @currency.id)
    end
  end
end
