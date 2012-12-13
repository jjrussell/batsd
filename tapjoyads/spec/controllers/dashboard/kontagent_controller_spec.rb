require "spec_helper"

describe Dashboard::KontagentController do
  let(:app)       { FactoryGirl.create(:app, :name => 'BazGame2') }
  let(:partner)   { FactoryGirl.create(:partner, :name => "BazCo2", :apps => [ app ]) }
  let(:subdomain) { 'baz2' }
  let(:user)      { FactoryGirl.create(:user, :current_partner => partner, :partners => [partner]) }

  let(:integration_request) do
    FactoryGirl.create(:kontagent_integration_request,
                       :partner => partner,
                       :user => user,
                       :subdomain  => subdomain)
  end

  before :each do
    activate_authlogic
    login_as(user)
    partner.kontagent_integration_requests << integration_request
  end

  around :each do |example|
    VCR.use_cassette('kontagent/controller', :record => :new_episodes) do
      example.run
    end
  end

  describe "#index" do
    context "when integrated with Kontagent" do
      before(:each) do
        partner.stub(:kontagent_enabled => true)
        controller.stub(:current_partner => partner)

        get :index
      end

      it "should assign the integration request" do
        integration_request.should eql(assigns(:kontagent_integration_request))
      end

      it "should render action (not redirect)" do
        response.should render_template(:index)
      end
    end

    context "when not integrated with Kontagent" do
      context "and outstanding request pending" do
        before(:each) do
          partner.stub(:kontagent_enabled => false)
          controller.stub(:current_partner => partner)
          integration_request.stub(:pending? => true)
          get :index
        end


        it "should assign integration request" do
          integration_request.should eql(assigns(:kontagent_integration_request))
        end

        it "should redirect to show" do
          response.should render_template(:show)
        end
      end

      context "and no outstanding request present" do
        before(:each) do
          integration_request.destroy
          get :index
        end

        it "should not assign integration request" do
          assigns(:kontagent_integration_request).should be_nil
        end

        it "should redirect to new integration request" do
          response.should redirect_to(:action => :new)
        end
      end
    end
  end

  describe "#new" do
    before(:each) { get :new }
    it "should prepare a new Kontagent integration request record" do
      assigns(:kontagent_integration_request).should be_new_record
    end
    it "should render the new integration form" do
      response.should render_template(:new)
    end
  end

  describe "#create" do
    context "when given a valid user and partner" do
      before(:each) do
        controller.stub(:current_partner) { partner }
        controller.stub(:current_user)    { user }
        kt_params = { :kontagent_integration_request => { :subdomain => subdomain }, :terms_and_conditions => true }
        post :create, kt_params
      end

      it "should construct the integration request successfully" do
        integration_request.to_s.should == assigns(:kontagent_integration_request).to_s
      end

      it "should be saved" do
        assigns(:kontagent_integration_request).should_not be_new_record
      end

      it "should render the show action" do
        response.should render_template(:show)
      end
    end
  end

  # TODO assert resync works (some weird routing error on try to put :update)
  describe "#update" do
    it "should attempt to resync" do
      KontagentIntegrationRequest.any_instance.should_receive(:resync!)

      Kontagent::Account.stub(:exists?)     { true }
      Kontagent::User.stub(:exists?)        { true }
      Kontagent::Application.stub(:exists?) { true }

      partner.stub    :kontagent_enabled => true,  :kontagent_subdomain => subdomain
      controller.stub :current_partner => partner, :current_user => user

      #put :update, :id => integration_request.id
      post :resync

      response.should redirect_to(:action => :index)
    end
  end
end
