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

  describe 'a non-rewarded featured offer' do
    it 'should be created' do
      @app.primary_non_rewarded_featured_offer.should be_nil

      post 'create', :app_id => @app.id, :offer_type => 'non_rewarded_featured'
      @app.reload
      offer = @app.primary_non_rewarded_featured_offer
      offer.should be_kind_of Offer
      offer.should_not be_rewarded
      offer.should be_featured

      response.should redirect_to :action => :edit, :id => offer.id
    end

    #it 'should have proper custom creative sizes' do

    #end
  end

  describe 'with a rewarded featured offer' do
    #it 'should be created' do

    #end

    #it 'should not show up as non-rewarded feautred offer' do

    #end

    #it 'should not show up as a non-rewarded offer' do

    #end

    #it 'should have proper custom creatives sizes' do

    #end
  end

  describe 'a non-rewarded offer' do
    #it 'should be created' do

    #end

    #it 'should not show up as a non-rewarded featured offer' do

    #end

    #it 'should have proper custom creative sizes' do

    #end
  end
end
