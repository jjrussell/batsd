require 'spec_helper'

describe Dashboard::Tools::UsersController do
  before :each do
    activate_authlogic
  end

  describe '#index' do
    before :each do
      UserRole.find_or_create_by_name('agency')
    end

    context 'when unauthorized' do
      before :each do
        user = FactoryGirl.create :user
        login_as user
        get(:index)
      end

      it 'redirects to the dashboard' do
        response.should redirect_to(root_path)
      end
    end

    context 'when admin' do
      before :each do
        @user = FactoryGirl.create :admin
        @user.current_partner = FactoryGirl.create :partner
        login_as @user
        get(:index)
      end

      it 'includes the list of tapjoy users' do
        assigns(:tapjoy_users).should include @user
      end
    end
  end

  describe '#show' do
    context 'when unauthorized' do
      before :each do
        user = FactoryGirl.create :user
        login_as user
        get(:show, :id => user.id)
      end

      it 'redirects to the dashboard' do
        response.should redirect_to(root_path)
      end
    end

    context 'when role manager' do
      before :each do
        user = FactoryGirl.create :role_manager_user
        user.current_partner = FactoryGirl.create :partner
        login_as user
        get(:show, :id => user.id)
      end

      it 'does not include partner data' do
        assigns(:partner_assignments).present? == false
        assigns(:current_assignments).present? == false
      end

      it 'includes roles' do
        assigns(:can_modify_roles).should be
      end
    end

    context 'when admin' do
      before :each do
        user = FactoryGirl.create :admin
        user.current_partner = FactoryGirl.create :partner
        login_as user
        get(:show, :id => user.id)
      end

      it 'includes partner data' do
        assigns(:partner_assignments).should be
        assigns(:current_assignments).should be
      end

      it 'includes roles' do
        assigns(:can_modify_roles).should be
      end
    end
  end
end
