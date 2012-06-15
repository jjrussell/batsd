require 'spec_helper'

describe Dashboard::Tools::GamersController do
  before :each do
    activate_authlogic
  end

  describe "#index" do
    context "when logged in as a customer service user" do
      include_context 'logged in as a customer service user'
    
      it "allows access" do
        get :index
        response.should be_success
      end
    end
    
    context "when logged in as an account manager" do
      include_context 'logged in as an account manager'
    
      it "allows access" do
        get :index
        response.should be_success
      end
    end
    
    context "when logged in as a partner" do
      include_context 'logged in as a partner'
    
      it "disallows access" do
        get :index
        response.should_not be_success
      end
    end
  end

  describe "#show" do
    let(:gamer)   { FactoryGirl.create(:gamer) }
    let(:params)  { { :id => gamer.id } }

    context "when logged in as a customer service user" do
      include_context 'logged in as a customer service user'
    
      it "allows access" do
        get(:show, params)
        response.should be_success
      end
    
      it "creates a gamer_profile for the gamer if one doesn't exist" do
        gamer.gamer_profile.should be_nil
        get(:show, params)
        assigns(:gamer).gamer_profile.should_not be_nil
      end
    end

    context "when logged in as an account manager" do
      include_context 'logged in as an account manager'
    
      it "allows access" do
        get(:show, params)
        response.should be_success
      end
    end
    
    context "when logged in as a partner" do
      include_context 'logged in as a partner'
    
      it "disallows access" do
        get(:show, params)
        response.should_not be_success
      end
    end
  end
end
