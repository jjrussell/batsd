require 'spec/spec_helper'

describe 'tools/index.html.haml' do
  context 'with a customer service user' do
    before :each do
      user = Factory :customer_service_user
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      render
    end

    it 'displays a link to gamer management' do
      response.should have_tag("a[href=?]", tools_gamers_path)
    end
    
    it 'displays the link to device management' do
      response.should have_tag("a[href=?]", internal_devices_path)
    end
  end

  context 'with an account manager user' do
    before :each do
      user = Factory :account_mgr_user
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      render
    end

    it 'displays a link to gamer management' do
      response.should have_tag("a[href=?]", tools_gamers_path)
    end
    
    it 'displays the link to device management' do
      response.should have_tag("a[href=?]", internal_devices_path)
    end
  end

  context 'with a partner user' do
    before :each do
      user = Factory :partner_user
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      render
    end

    it 'hides the link to gamer management' do
      response.should_not have_tag("a[href=?]", tools_gamers_path)
    end
    
    it 'hides the link to device management' do
      response.should_not have_tag("a[href=?]", internal_devices_path)
    end
  end
  
  context 'with a role admin user' do
    before :each do
      user = Factory :role_admin_user
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      render
    end
    
    it 'displays the link to role management' do
      response.should have_tag("a[href=?]", tools_users_path)
    end
    
    it 'hides the link to device management' do
      response.should_not have_tag("a[href=?]", internal_devices_path)
    end
  end
  
  context 'with an admin user' do
    before :each do
      user = Factory :admin
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      render
    end
    
    it 'displays the link to role management' do
      response.should have_tag("a[href=?]", tools_users_path)
    end
    
    it 'displays the link to device management' do
      response.should have_tag("a[href=?]", internal_devices_path)
    end
  end
end
