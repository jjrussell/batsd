require 'spec_helper'

describe ToolsController do
  before :each do
    activate_authlogic
  end

  context 'with a non-logged in user' do
    it 'redirects to login page' do
      get(:index)
      response.should redirect_to(login_path(:goto => tools_path))
    end
  end

  context 'with an unauthorized user' do
    before :each do
      @user = Factory(:agency_user)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      login_as(@user)
    end

    context 'accessing tools index' do
      it 'redirects to dashboard' do
        get(:index)
        response.should redirect_to(dashboard_root_path)
      end
    end
  end

  context 'with an admin user' do
    before :each do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      login_as(@user)
    end

    context 'accessing tools index' do
      it 'renders appropriate page' do
        get(:index)
        response.should render_template 'tools/index'
      end
    end
  end
end
