require 'spec_helper'

describe AgencyApi::AppsController do

  describe '#index' do
    before :each do
      agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
      @valid_params = {
        :agency_id => agency_user.id,
        :api_key => agency_user.api_key,
        :partner_id => @partner.id
      }
    end

    context 'with missing params' do
      before :each do
        get(:index)
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
      end
    end

    context 'with bad credentials' do
      before :each do
        get(:index, @valid_params.merge(:api_key => 'foo'))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end

    context 'with an invalid partner_id' do
      before :each do
        partner2 = Factory(:partner)
        get(:index, @valid_params.merge(:partner_id => partner2.id))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end

    context 'with valid params' do
      before :each do
        get(:index, @valid_params)
      end

      it 'responds with success' do
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        result['apps'].should == [{ 'app_id' => @app.id, 'name' => @app.name, 'platform' => @app.platform, 'store_id' => @app.store_id }]
      end
    end
  end

  describe '#show' do
    before :each do
      agency_user = Factory(:agency_user)
      partner = Factory(:partner)
      PartnerAssignment.create!(:user => agency_user, :partner => partner)
      @app = Factory(:app, :partner => partner)
      @valid_params = {
        :id => @app.id,
        :agency_id => agency_user.id,
        :api_key => agency_user.api_key
      }
    end

    context 'with missing params' do
      before :each do
        get(:show)
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
      end
    end

    context 'with bad credentials' do
      before :each do
        get(:show, @valid_params.merge(:api_key => 'foo'))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end

    context 'with an invalid app_id' do
      before :each do
        get(:show, @valid_params.merge(:id => 'foo'))
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
      end
    end

    context 'with an app_id belonging to an invalid partner' do
      before :each do
        app2 = Factory(:app)
        get(:show, @valid_params.merge(:id => app2.id))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end
    context 'with valid params' do
      before :each do
        get(:show, @valid_params)
      end

      it 'responds with success' do
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        result['app_id'].should == @app.id
        result['name'].should == @app.name
        result['platform'].should == @app.platform
        result['store_id'].should == @app.store_id
        result['app_secret_key'].should == @app.secret_key
        result['integrated'].should == @app.primary_offer.integrated?
        result['integrated'].should be_false
      end
    end
  end

  describe '#create' do
    before :each do
      agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => agency_user, :partner => @partner)
      @valid_params = {
        :agency_id => agency_user.id,
        :api_key => agency_user.api_key,
        :partner_id => @partner.id,
        :name => 'app',
        :platform => 'iphone'
      }
    end

    context 'with missing params' do
      before :each do
        post(:create)
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
      end
    end
    context 'with bad credentials' do
      before :each do
        post(:create, @valid_params.merge(:api_key => 'foo'))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end
    context 'with an invalid partner_id' do
      before :each do
        partner2 = Factory(:partner)
        post(:create, @valid_params.merge(:partner_id => partner2.id))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end
    context 'with invalid platform' do
      before :each do
        post(:create, @valid_params.merge(:platform => 'foo'))
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
      end
    end

    context 'with valid params' do
      before :each do
        post(:create, @valid_params)
      end

      it 'responds with success' do
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        @partner.apps.count.should == 1
        app = @partner.apps.first
        app.id.should == result['app_id']
        app.secret_key.should == result['app_secret_key']
        app.store_id.should == nil
      end

      it 'assigns store id' do
        Sqs.expects(:send_message).with(QueueNames::GET_STORE_INFO, regexp_matches(/(\w+-){4}\w+/))
        post(:create, @valid_params.merge(:store_id => 'wah!'))
        result = JSON.parse(response.body)
        result['success'].should be_true
        app = App.find(result['app_id'])
        app.store_id.should == 'wah!'
      end

      it 'saves activity logs' do
        controller.expects :log_activity
        controller.expects :save_activity_logs
        post(:create, @valid_params)
      end
    end
  end

  describe '#update' do
    before :each do
      agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
      @valid_params = {
        :id => @app.id,
        :agency_id => agency_user.id,
        :api_key => agency_user.api_key,
        :name => 'foo'
      }
    end

    context 'with missing params' do
      before :each do
        put(:update)
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
      end
    end

    context 'with bad credentials' do
      before :each do
        put(:update, @valid_params.merge(:api_key => 'foo'))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end

    context 'with an invalid id' do
      before :each do
        put(:update, @valid_params.merge(:id => 'foo'))
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
        result = JSON.parse(response.body)
        result['error'].should == 'app not found'
      end
    end

    context 'with an id belonging to an invalid partner' do
      before :each do
        app2 = Factory(:app)
        put(:update, @valid_params.merge(:id => app2.id))
      end

      it 'responds with error' do
        should_respond_with_json_error(403)
      end
    end

    context 'with invalid app' do
      before :each do
        @app.platform = 'pizza'
        @app.send(:update_without_callbacks)
        put(:update, @valid_params)
      end

      it 'responds with error' do
        should_respond_with_json_error(400)
        result = JSON.parse(response.body)
        result['error'].join(' ').should == 'platform is not included in the list'
      end
    end

    context 'with valid params' do
      before :each do
        put(:update, @valid_params)
      end

      it 'responds with success' do
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        @partner.apps.count.should == 1
        app = @partner.apps.first
        app.name.should == 'foo'
      end

      it 'saves activity logs' do
        controller.expects :log_activity
        controller.expects :save_activity_logs
        put(:update, @valid_params)
      end

      it 'changes store id' do
        Sqs.expects(:send_message).with(QueueNames::GET_STORE_INFO, regexp_matches(/(\w+-){4}\w+/))
        put(:update, @valid_params.merge(:store_id => 'wah!'))
        result = JSON.parse(response.body)
        result['success'].should be_true
        @app.reload
        @app.store_id.should == 'wah!'
      end
    end
  end
end
