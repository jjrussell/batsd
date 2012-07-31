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

  describe '#set_custom_url_scheme' do
    context 'with a valid partner app' do
      it 'sets the custom url scheme' do
        app = @partner.apps.last
        options = { :app_id => app.id, :custom_url_scheme => 'CUSTOM_URL_SCHEME' }
        get(:set_custom_url_scheme, options)
        should_respond_with_json_success(200)

        app= App.find(app.id)
        app.custom_url_scheme.should == 'CUSTOM_URL_SCHEME'
      end
    end

    context 'without a partner app' do
      it 'returns an error' do
        options = { :app_id => FactoryGirl.create(:app).id, :custom_url_scheme => 'CUSTOM_URL_SCHEME' }
        get(:set_custom_url_scheme, options)
        should_respond_with_json_error(403)
      end
    end
  end
end
