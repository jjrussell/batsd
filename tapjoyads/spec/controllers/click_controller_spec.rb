require 'spec/spec_helper'

describe ClickController do

  before :each do
    fake_the_web
    activate_authlogic
    @user = Factory(:user)
    @partner = Factory(:partner,
      :pending_earnings => 10000,
      :balance => 10000,
      :users => [@user]
    )
    @offer = Factory(:app).primary_offer
    @offer.tapjoy_enabled = true
    @offer.payment = 1
    @offer.user_enabled = true
    Factory(:app, :partner => @partner)
    Factory(:app, :partner => @partner)
    @currency = Factory(:currency)
    login_as(@user)
  end

  describe "#generic" do
    context "with a vanilla user" do
      before :each do
        @params = {
          :udid => 'stuff',
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id,
          :advertiser_app_id => 'even_more_stuff'
        }
      end

      it "should should redirect to a guid url" do
        controller.stubs(:verify_params).returns(true)
        Offer.stubs(:find_in_cache).returns(@offer)
        Currency.stubs(:find_in_cache).returns(@currency)
        post(:generic, @params)
        assigns(:click).should_not be_nil
        assigns(:click).id.should == 'stuff.even_more_stuff'
        assigns(:generic_offer_click).should_not be_nil
        response.should be_redirect
      end
    end
  end

  describe "#app" do
    context "with a vanilla user" do
      before :each do
        @params = {
          :udid => 'app_stuff',
          :offer_id => @offer.id,
          :viewed_at =>  (Time.zone.now - 1.hour).to_f,
          :currency_id => @currency.id,
          :advertiser_app_id => 'even_more_app_stuff'
        }
      end
      
      it "should should redirect to a guid url" do
        controller.stubs(:verify_params).returns(true)
        Offer.stubs(:find_in_cache).returns(@offer)
        Currency.stubs(:find_in_cache).returns(@currency)
        post(:app, @params)
        assigns(:click).should_not be_nil
        assigns(:click).id.should == 'app_stuff.even_more_app_stuff'
        assigns(:generic_offer_click).should be_nil
        response.should be_redirect
      end

    end
  end
end
