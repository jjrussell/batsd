require 'spec_helper'

describe Dashboard::ActionOffersController do
  before :each do
    activate_authlogic
    @user = FactoryGirl.create(:user)
    @partner = FactoryGirl.create(:partner,
      :pending_earnings => 10000,
      :balance => 10000,
      :users => [@user]
    )
    app = FactoryGirl.create(:app, :partner => @partner)
    action_offer = FactoryGirl.create(:action_offer, :partner => @partner, :app => app)
    @params = {
      :id => action_offer.id,
      :app_id => action_offer.app_id,
    }
    login_as(@user)
  end

  describe '#TJCPPA.h' do
    before :each do
      @params[:format] = 'h'
    end

    it 'downloads the header file' do
      lambda { get :TJCPPA, @params }.should_not raise_exception
    end
  end

  describe '#TapjoyPPA.java' do
    before :each do
      @params[:format] = 'java'
    end

    it 'downloads the java file' do
      lambda { get :TapjoyPPA, @params }.should_not raise_exception
    end
  end
end
