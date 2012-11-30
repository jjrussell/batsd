require 'spec_helper'

describe KontagentIntegrationRequest do
  around(:each) do |example|
    VCR.use_cassette('kontagent/integration_request', :record => :new_episodes) do
      example.run
    end
  end

  let(:title)      { 'abcSomeCool'}
  let(:app_id)     { 432216 }
  let(:user_id)    { 342547 }
  let(:partner_id) { 352428 }

  let(:app)     { FactoryGirl.create(:app,
                                     :name => "#{title}App",
                                     :id => UUIDTools::UUID.parse_int(app_id).to_s ) }

  let(:user)    { FactoryGirl.create(:user,
                                     :email => 'some.one@any.net',
                                     :id => UUIDTools::UUID.parse_int(user_id).to_s) }

  let(:partner) { FactoryGirl.create(:partner,
                                     :name => "#{title}Account",
                                     :apps => [ app ],
                                     :users => [ user ],
                                     :id => UUIDTools::UUID.parse_int(partner_id).to_s)}

  let(:integration_request)       { FactoryGirl.create(:kontagent_integration_request,
                                                       :partner => partner,
                                                       :user => user,
                                                       :subdomain => title[0..5].downcase) }

  before(:each) do
    user.current_partner = partner
    integration_request.provision!
  end

  describe "#provision!" do
    context "maps Tapjoy resources to Kontagent resources" do
      describe "maps Tapjoy Partner to Kontagent Account" do
        it "should provision Partner successfully" do
          partner.should be_kontagent_enabled
        end
        it "should provision Partner with a KT subdomain" do
          partner.kontagent_subdomain?.should be_true
          partner.kontagent_subdomain.should_not be_nil
        end
        context "and matching remote Account resource" do
          subject { KontagentHelpers.find!(partner) }
          it "should be unique" do
            should have(1).item
          end
          it "should have Partner name" do
            subject.first['name'].should == partner.name
          end
          it "should have Partner ID" do
            subject.first['account_id'].should == KontagentHelpers.id_for(partner).to_s
          end
        end
      end

      describe "maps Tapjoy App to Kontagent Application" do
        before(:each) { app.reload }
        it "should provision App successfully" do
          app.should be_kontagent_enabled
        end

        it "should provision App with an API key" do
          app.kontagent_api_key?.should be_true
          app.kontagent_api_key.should_not be_nil
        end

        context "and matching remote Application resource" do
          subject { KontagentHelpers.find!(app) }
          it "should be unique" do
            should have(1).item
          end
          it "should have App name" do
            subject.first['name'].should == app.name
          end
          it "should have App ID" do
            subject.first['application_id'].should == KontagentHelpers.id_for(app).to_s
          end
          it "should have Partner ID" do
            subject.first['account_id'].should == KontagentHelpers.id_for(partner).to_s
          end
        end
      end

      describe "maps Tapjoy User to Kontagent User" do
        before(:each) { user.reload }
        it "should provision User successfully" do
          user.should be_kontagent_enabled
        end
        context "and matching remote User resource" do
          subject { KontagentHelpers.find!(user) }
          it "should be unique" do
            should have(1).item
          end
          it "should have User email as remote username" do
            subject.first['username'].should == user.email
          end
          it "should have User ID" do
            subject.first['user_id'].should == KontagentHelpers.id_for(user).to_s
          end
          it "should have Account ID" do
            subject.first['account_id'].should == KontagentHelpers.id_for(partner).to_s
          end
        end
      end
    end
  end

  describe "#resync!" do
    let(:new_app_id)  { 515398043 }
    let(:new_user_id) { 629803450 }

    it "should check whether re-provisioning resources is needed" do
      Kontagent::Account.should_receive(:exists?)      { true }
      Kontagent::User.should_receive(:exists?)         { true }
      Kontagent::Application.should_receive(:exists?)  { true }
      integration_request.resync!
    end

    it "should re-provision entities if matching remote resources don't exist" do
      Kontagent::Account.should_receive(:exists?)            { true }
      Kontagent::User.should_receive(:exists?)               { false }
      Kontagent::Application.should_receive(:exists?).twice  { false }

      integration_request.should_receive(:provision_app!).twice  { true }
      integration_request.should_receive(:provision_user!)       { true }

      another_app = FactoryGirl.create(:app,
                         :name => "#{title}App",
                         :id => UUIDTools::UUID.parse_int(new_app_id).to_s )
      partner.apps += [another_app]

      another_user =  FactoryGirl.create(:user,
                                         :email => 'another.one@any.net',
                                         :id => UUIDTools::UUID.parse_int(new_user_id).to_s)
      integration_request.user = another_user
      integration_request.resync!
    end
  end
end
