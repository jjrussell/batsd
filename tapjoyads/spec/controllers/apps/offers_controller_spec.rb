require 'spec/spec_helper'

describe Apps::OffersController do
  before :each do
    activate_authlogic
  end

  before :each do
    @user = Factory :admin
    @partner = Factory :partner, :users => [@user]
    @app = Factory :app, :partner => @partner
    login_as @user
  end

  it 'should not have any offers initially' do
    @app.primary_non_rewarded_featured_offer.should be_nil
    @app.primary_rewarded_featured_offer.should be_nil
    @app.primary_non_rewarded_offer.should be_nil
  end

  context 'a non-rewarded featured offer' do
    before :each do
      post :create, :app_id => @app.id, :offer_type => 'non_rewarded_featured'
    end

    it 'should be created' do
      offer = @app.primary_non_rewarded_featured_offer
      offer.should be_a Offer
      offer.should_not be_rewarded
      offer.should be_featured
      response.should redirect_to :action => :edit, :id => offer.id
    end

    it 'should not show up as rewarded featured offer' do
      @app.primary_rewarded_featured_offer.should be_nil
    end

    it 'should not show up as a non-rewarded offer' do
      @app.primary_non_rewarded_offer.should be_nil
    end

    it 'should allow proper custom creative sizes' do
      @app.reload
      get :edit, :app_id => @app.id, :id => @app.primary_non_rewarded_featured_offer.id
      response.should be_success
      Offer::FEATURED_AD_SIZES.each do |size|
        assigns(:custom_creative_sizes).collect { |hash| hash[:image_size] }.should include(size)
      end
    end
  end

  context 'with a rewarded featured offer' do
    before :each do
      post :create, :app_id => @app.id, :offer_type => 'rewarded_featured'
    end

    it 'should be created' do
      offer = @app.primary_rewarded_featured_offer
      offer.should be_a Offer
      offer.should be_rewarded
      offer.should be_featured
      response.should redirect_to :action => :edit, :id => offer.id
    end

    it 'should not show up as non-rewarded feautred offer' do
      @app.primary_non_rewarded_featured_offer.should be_nil
    end

    it 'should not show up as a non-rewarded offer' do
      @app.primary_non_rewarded_offer.should be_nil
    end

    it 'should allow proper custom creative sizes' do
      @app.reload
      get :edit, :app_id => @app.id, :id => @app.primary_rewarded_featured_offer.id
      response.should be_success
      Offer::FEATURED_AD_SIZES.each do |size|
        assigns(:custom_creative_sizes).collect { |hash| hash[:image_size] }.should include(size)
      end
    end
  end

  context 'a non-rewarded offer' do
    before :each do
      post :create, :app_id => @app.id, :offer_type => 'non_rewarded'
    end

    it 'should be created' do
      offer = @app.primary_non_rewarded_offer
      offer.should be_a Offer
      offer.should_not be_rewarded
      offer.should_not be_featured
      response.should redirect_to :action => :edit, :id => offer.id
    end

    it 'should not show up as a featured offer' do
      @app.primary_non_rewarded_featured_offer.should be_nil
      @app.primary_rewarded_featured_offer.should be_nil
    end

    it 'should have proper custom creative sizes' do
      @app.reload
      get :edit, :app_id => @app.id, :id => @app.primary_non_rewarded_offer.id
      response.should be_success
      Offer::DISPLAY_AD_SIZES.each do |size|
        assigns(:custom_creative_sizes).collect { |hash| hash[:image_size] }.should include(size)
      end
    end
  end
end
