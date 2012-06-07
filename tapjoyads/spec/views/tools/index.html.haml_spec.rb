#TODO: rails3 replace with BDD
#require 'spec/spec_helper'

#describe 'tools/index.html.haml' do
  #context 'with a customer service user' do
    #before :each do
      #user = Factory :customer_service_user
      #controller.stub(:current_user).and_return(user)
      #view.stub(:current_user).and_return(user)
      #view.stub(:has_permissions_for_one_of?).and_return(true)
      #render
    #end

    #it 'displays a link to gamer management' do
      #rendered.should have_link("Gamer Accounts", :href => tools_gamers_path)
    #end

    #it 'displays the link to device management' do
      #rendered.should have_link("All approved devices", :href => internal_devices_path)
    #end
  #end

  #context 'with an account manager user' do
    #before :each do
      #user = Factory :account_mgr_user
      #controller.stub(:current_user).and_return(user)
      #view.stub(:current_user).and_return(user)
      #view.stub(:has_permissions_for_one_of?).and_return(true)
      #render
    #end

    #it 'displays a link to gamer management' do
      #rendered.should have_link("Gamer Accounts", :href => tools_gamers_path)
    #end

    #it 'displays the link to device management' do
      #rendered.should have_link("All approved devices", :href => internal_devices_path)
    #end
  #end

  #context 'with a partner user' do
    #before :each do
      #user = Factory :partner_user
      #controller.stub(:current_user).and_return(user)
      #view.stub(:current_user).and_return(user)
      #view.stub(:has_permissions_for_one_of?).and_return(false)
      #render
    #end

    #it 'hides the link to gamer management' do
      #rendered.should_not have_link("Gamer Accounts")
    #end

    #it 'hides the link to device management' do
      #rendered.should_not have_link("All approved devices")
    #end
  #end

  #context 'with a role manager user' do
    #before :each do
      #user = Factory :role_mgr_user
      #controller.stub(:current_user).and_return(user)
      #view.stub(:current_user).and_return(user)
      #view.stub(:has_permissions_for_one_of?).and_return(true)
      #render
    #end

    #it 'displays the link to role management' do
      #puts rendered
      #rendered.should have_link(tools_users_path)
    #end

    #it 'hides the link to device management' do
      #rendered.should_not have_link(internal_devices_path)
    #end
  #end

  #context 'with an admin user' do
    #before :each do
      #user = Factory :admin
      #controller.stub(:current_user).and_return(user)
      #view.stub(:current_user).and_return(user)
      #render
    #end

    #it 'displays the link to role management' do
      #rendered.should have_link("User Accounts", :href => tools_users_path)
    #end

    #it 'displays the link to device management' do
      #rendered.should have_link("All approved devices", :href => internal_devices_path)
    #end
  #end
#end
