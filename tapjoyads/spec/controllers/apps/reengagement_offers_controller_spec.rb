require 'spec/spec_helper'

describe Apps::ReengagementOffersController do
  before :each do
    activate_authlogic
  end

  before :each do
    @user = Factory :admin
    @partner = Factory(:partner, :users => [@user])
    @app = Factory(:app, :partner => @partner)

    login_as @user
  end

  it 'should not have any reengagement offers initially' do
    @app.reengagement_campaign.should be_nil
  end

  describe "#create" do

    before :each do
      post :create, :app_id => @app.id, :partner => @partner, :reward_value => 2, :currency_id => @app.primary_currency.id, :instructions => "french toast"
      response.should redirect_to(:action => :index, :app_id => @app.id)
    end
            
    it 'should create a reengagement offer' do
      ro = @app.reengagement_campaign.last
      ro.should be_a ReengagementOffer
      ro.should == @app.reengagement_campaign[ro.day_number]
    end

    it 'should disable the entire reengagement campaign' do
      @app.reengagement_campaign_enabled.should == false
    end

  end

  describe "#new" do

    it 'should automatically create a day 0 reengagement offer' do
      ro = @app.reengagement_campaign.first
      ro.should be_a ReengagementOffer
      ro.day_number.should == 0
      ro.instructions.should == 'Come back each day and get rewards!'
      ro.reward_value.should == 0
      response.should redirect_to(:action => :index, :app_id => @app.id)
    end

    it 'should redirect when reengagement campaign longer than 5 days'
      num_to_create = 5 - @app.reengagement_campaign.last.day_number
      num_to_create.times.each do
        post :create, :app_id => @app.id, :partner => @partner, :reward_value => 2, :currency_id => @app.primary_currency.id, :instructions => "french toast"     
      end
      get :new, :app_id => @app.id, :partner => @partner
      response.should redirect_to(:action => :index, :app_id => @app.id)
  end

  describe "#index" do

    it 'should redirect to #new if no reengagement offers exist' do
      ReengagementOffer.all.map(&:delete!)
      get :index, :app_id => @app.id
      response.should redirect_to(:action => :new, :app_id => @app.id)
    end

  end

  describe "#update" do

    before :each do
      @ro = @app.reengagement_campaign.last
      post :update, :app_id => @app.id, :reengagement_offer_id => @ro.id, :currency_id => @app.primary_currency.id, :reward_value => 12, :instructions => "pancackes"
      response.should redirect_to(:action => :index, :app_id => @app.id)
    end

    it 'should update a reengagement offer' do
      updated_ro = @app.reengagement_campaign.last

      @ro.id.should                == updated_ro.id
      @ro.day_number.should        == updated_ro.day_number
      @ro.currency_id.should       == updated_ro.currency_id
      @ro.reward_value.should_not  == updated_ro.reward_value
      @ro.instructions.should_not  == updated_ro.instructions
    end

    it 'should disable the entire reengagement campaign' do
      @app.reengagement_campaign_enabled.should == false
    end

  end

  describe "#destroy" do

    before :each do
      if @app.reengagement_campaign_length == 1
        post :create, :app_id => @app.id, :partner => @partner, :reward_value => 3, :currency_id => @app.primary_currency.id, :instructions => "more french toast"
      end
      @ro = @app.reengagement_campaign.last
      post :destroy, :app_id => @app.id, :reengagement_offer_id => @ro.id
      response.should redirect_to(:action => :index, :app_id => @app.id)
    end

    it 'should hide a reengagement offer instead of actually destroying it' do
      ro = ReengagementOffer.find(@ro.id)
      ro.should_not be_nil
      ro.hidden.should == true
    end

    it 'should not be able to hide any reengagement offer other than the last' do
      if @app.reengagement_campaign_length == 1
        post :create, :app_id => @app.id, :partner => @partner, :reward_value => 3, :currency_id => @app.primary_currency.id, :instructions => "more french toast"
      end
      post :destroy, :app_id => @app.id, :reengagement_offer_id => @app.reengagement_campaign.first.id
      @app.reengagement_campaign.first.hidden.should_not == true
    end

    it 'should disable the entire reengagement campaign' do
      @app.reengagement_campaign_enabled.should == false
    end
  
  end

  describe "#update_status" do

    before :each do
      @ro = @app.reengagement_campaign.last
    end

    it 'should enable a campaign'
      post :update_status, :enabled => '1', :app_id => @app.id, :reengagement_offer_id => @ro.id
      

    it 'should enable the campaign only when \'1\' is passed'
      post 
      
    end

  end

