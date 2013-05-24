require 'spec_helper'

describe CouponsController do
  render_views
  before :each do
    @app = FactoryGirl.create(:app)
    App.stub(:find_in_cache).and_return(@app)
    @offer = @app.primary_offer
    Offer.stub(:find_in_cache).and_return(@offer)
    @currency = FactoryGirl.create(:currency)
    @currency.stub(:active_and_future_sales).and_return({})
    Currency.stub(:find_in_cache).and_return(@currency)
    params = { :udid => '123', :publisher_app_id => 'pub_id',
               :click_key => 'click', :currency_id => @currency.id,
               :id => @offer.id, :offer_id => @offer.id,
               :app_id => @app.id
             }
    @params = ObjectEncryptor.encrypt(params)
    @coupon = FactoryGirl.create(:coupon)
    Coupon.stub(:find_in_cache).and_return(@coupon)
  end
  describe '#complete' do
    before :each do
      get(:complete, :data => @params)
    end
    it 'should have coupon instance variable' do
      assigns(:coupon).should == @coupon
    end
    it 'should have offer instance variable' do
      assigns(:offer).should == @offer
    end
    it 'should have currency instance variable' do
      assigns(:currency).should == @currency
    end
    it 'should have publisher app instance variable' do
      assigns(:publisher_app).should == @app
    end
    it 'responds with 200' do
      should respond_with 200
    end
    it 'renders coupons/complete template' do
      should render_template('coupons/complete')
    end
  end
end
