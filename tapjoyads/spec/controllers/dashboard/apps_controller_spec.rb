require 'spec_helper'

describe Dashboard::AppsController do
  before :each do
    activate_authlogic
    @user = FactoryGirl.create(:user)
    @partner = FactoryGirl.create(:partner,
      :pending_earnings => 10000,
      :balance => 10000,
      :users => [@user]
    )
    FactoryGirl.create(:app, :partner => @partner)
    FactoryGirl.create(:app, :partner => @partner)
    login_as(@user)
  end

  describe '#index' do
    context 'with an admin user' do
      before :each do
        @user.user_roles << UserRole.find_or_create_by_name('admin')
      end

      it 'redirects to show an app they own' do
        get(:index)
        response.should be_redirect
      end

      it 'assigns an arbitrary app they own' do
        get(:index)
        @partner.apps.should include(assigns(:app))
      end

      it 'assigns the last app visited' do
        last_app = @partner.apps.last
        get(:show, :id => last_app.id)
        get(:index)
        last_app.should == assigns(:app)
      end
    end

    context 'with a user with apps' do
      it 'redirects to show an app they own' do
        get(:index)
        response.should be_redirect
      end

      it 'assigns an arbitrary app' do
        get(:index)
        @partner.apps.should include(assigns(:app))
      end

      it 'assigns the last app visited' do
        last_app = @partner.apps.last
        get(:show, :id => last_app.id)
        get(:index)
        last_app.should == assigns(:app)
      end
    end

    context 'with a user without apps' do
      before :each do
        @partner.apps.delete_all
      end

      it 'redirects to app creation page' do
        get(:index)
        response.should redirect_to(new_app_path)
      end
    end
  end

  describe '#show' do
    context 'with an admin user' do
      before :each do
        @user.user_roles << UserRole.find_or_create_by_name('admin')
      end

      it 'shows apps from another partner' do
        someone_else = FactoryGirl.create(:partner,
          :pending_earnings => 10000,
          :balance => 10000
        )
        not_my_app = FactoryGirl.create(:app, :partner => someone_else)
        get(:show, :id => not_my_app.id)
        response.should be_success
      end

      it 'assigns the last app visited' do
        last_app = @partner.apps.last
        get(:show, :id => last_app.id)
        last_app.should == assigns(:app)
      end

      it 'saves the id of the last app visited in the session' do
        last_app = @partner.apps.last
        get(:show, :id => last_app.id)
        last_app.id.should == session[:last_shown_app]
      end
    end

    context 'with a user with apps' do
      it 'assigns the last app visited' do
        last_app = @partner.apps.last
        get(:show, :id => last_app.id)
        last_app.should == assigns(:app)
      end

      it 'saves the id of the last app visited in the session' do
        last_app = @partner.apps.last
        get(:show, :id => last_app.id)
        last_app.id.should == session[:last_shown_app]
      end

      it 'does not show apps from another publisher' do
        someone_else = FactoryGirl.create(:partner,
          :pending_earnings => 10000,
          :balance => 10000
        )
        not_my_app = FactoryGirl.create(:app, :partner => someone_else)
        get(:show, :id => not_my_app.id)
        response.should be_redirect
      end
    end

    context 'with a user without apps' do
      before :each do
        @partner.apps.delete_all
      end

      it 'redirects to app creation page' do
        someone_else = FactoryGirl.create(:partner,
          :pending_earnings => 10000,
          :balance => 10000
        )
        not_my_app = FactoryGirl.create(:app, :partner => someone_else)
        get(:show, :id => not_my_app.id)
        response.should redirect_to(new_app_path)
      end
    end
  end

  describe '#update' do
    before :each do
      @app = FactoryGirl.create(:app, :partner => @partner)
      @params = { :id => @app.id, :app => { :name => @app.name }, :state => 'live', :store_id => @app.store_id }
      App.any_instance.stub(:update_app_metadata).and_return(@app.primary_app_metadata)
      @app.primary_app_metadata.stub(:update_from_store).and_return(nil)
    end

    context 'successful update' do
      before :each do
        @app.primary_app_metadata.stub(:update_from_store).and_return(nil)
        put(:update, @params)
      end

      it 'has a flash notice' do
        flash[:notice].should == 'App was successfully updated.'
      end
    end

    context 'unsuccessful update' do
      before :each do
        @app.primary_app_metadata.stub(:update_from_store).and_raise('failed to update from store')
        put(:update, @params)
      end

      it 'has a flash error' do
        flash.now[:error].should == 'Grabbing app data from app store failed. Please try again.'
      end
      it 'renders show template' do
        response.should render_template('show')
      end
    end
  end
end
