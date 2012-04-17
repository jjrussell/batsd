require 'spec_helper'

describe SearchController do
  before :each do
    activate_authlogic
  end

  describe "#gamers" do
    context 'with a non-logged in user' do
      it 'redirects to login page' do
        get :gamers
        response.should redirect_to(login_path(:goto => search_gamers_path))
      end
    end

    context 'with an unauthorized user' do
      before :each do
        @user = Factory(:agency_user)
        login_as(@user)
      end

      context 'searching for gamers' do
        it 'redirects to dashboard' do
          get :gamers
          response.should redirect_to(dashboard_root_path)
        end
      end
    end

    context 'with an admin user' do
      before :each do
        @user = Factory(:admin)
        login_as(@user)
      end

      context 'with a blank search query' do
        before :each do
          @params = { :terms => '' }
        end

      end
    end
  end
end
