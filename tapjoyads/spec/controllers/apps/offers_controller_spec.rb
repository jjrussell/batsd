require 'spec/spec_helper'

describe Apps::OffersController do
  before :each do
    activate_authlogic
  end

  before :each do
    @user = Factory :admin
    @partner = Factory(:partner, :users => [@user])
    @app = Factory(:app, :partner => @partner)
    login_as @user
  end

  it 'does not have any offers initially' do
    @app.primary_non_rewarded_featured_offer.should be_nil
    @app.primary_rewarded_featured_offer.should be_nil
    @app.primary_non_rewarded_offer.should be_nil
  end

  context 'a non-rewarded featured offer' do
    before :each do
      post :create, :app_id => @app.id, :offer_type => 'non_rewarded_featured'
    end

    it 'is created' do
      offer = @app.primary_non_rewarded_featured_offer
      offer.should be_a Offer
      offer.should_not be_rewarded
      offer.should be_featured
      response.should redirect_to(:action => :edit, :id => offer.id)
    end

    it 'does not show up as a rewarded featured offer' do
      @app.primary_rewarded_featured_offer.should be_nil
    end

    it 'does not show up as a non-rewarded offer' do
      @app.primary_non_rewarded_offer.should be_nil
    end
  end

  context 'with a rewarded featured offer' do
    before :each do
      post :create, :app_id => @app.id, :offer_type => 'rewarded_featured'
    end

    it 'is created' do
      offer = @app.primary_rewarded_featured_offer
      offer.should be_a Offer
      offer.should be_rewarded
      offer.should be_featured
      response.should redirect_to(:action => :edit, :id => offer.id)
    end

    it 'does not show up as a non-rewarded featured offer' do
      @app.primary_non_rewarded_featured_offer.should be_nil
    end

    it 'does not show up as a non-rewarded offer' do
      @app.primary_non_rewarded_offer.should be_nil
    end
  end

  context 'a non-rewarded offer' do
    before :each do
      post :create, :app_id => @app.id, :offer_type => 'non_rewarded'
    end

    it 'is created' do
      offer = @app.primary_non_rewarded_offer
      offer.should be_a Offer
      offer.should_not be_rewarded
      offer.should_not be_featured
      response.should redirect_to(:action => :edit, :id => offer.id)
    end

    it 'does not show up as a featured offer' do
      @app.primary_non_rewarded_featured_offer.should be_nil
      @app.primary_rewarded_featured_offer.should be_nil
    end
  end
end
