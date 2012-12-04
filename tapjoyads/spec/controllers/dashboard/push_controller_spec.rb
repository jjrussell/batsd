require 'spec_helper'

describe Dashboard::PushController do
  before(:each) do
   activate_authlogic
    @user = FactoryGirl.create(:user)
    @partner = FactoryGirl.create(:partner,
      :pending_earnings => 10000,
      :balance => 10000,
      :users => [@user]
    )
    @app = FactoryGirl.create(:app, :partner => @partner, :notifications_enabled => false)
    login_as(@user)

    NotificationsClient::App.any_instance.stub(:update)
  end

  describe 'update' do
    def do_request(opts={})
      post :update, opts.reverse_merge(:app_id => @app.id, :app => {:notifications_enabled => true})
    end

    it 'should update notifications_enabled attr' do
      do_request
      @app.reload.notifications_enabled.should == true
    end

    it 'should redirect to push index' do
      do_request
      response.should redirect_to(app_push_index_path(@app))
    end

    it 'should rollback if setting app_secret fails' do
      NotificationsClient::App.any_instance.should_receive(:update).and_raise
      do_request
      @app.reload.notifications_enabled.should == false
    end

    it 'should create a notification app' do
      NotificationsClient::App.should_receive(:new).with(hash_including(:app_id => @app.id, :app => {
        :secret_key => @app.secret_key,
        :platform => @app.platform,
        :name => @app.name
        }))
      do_request
    end

    it 'should update a notification app when notifications are enabled' do
      NotificationsClient::App.any_instance.should_receive(:update)
      do_request
    end

    it 'should not update a notification app when notifications are disabled' do
      NotificationsClient::App.any_instance.should_not_receive(:update)
      do_request(:app => {:notifications_enabled => false})
    end
  end
end

