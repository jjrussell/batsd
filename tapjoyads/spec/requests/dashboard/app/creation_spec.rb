require 'spec_helper'

describe "App creation", :type => :request do

  before :each do
    fake_the_web
    activate_authlogic
  end

  describe "Creating an app as a new user" do
    it "creates an app and account" do
      capybara_register

      visit '/apps/new'
      fill_in "app_name", :with => "new app"
      click_button "Add App"

      page.should have_content('App was successfully created')
    end
  end

  describe "Creating a second app as an existing user" do
    it "should create a second app" do
      capybara_dashboard_login

      click_link "Apps"
      click_button "Add App"
      fill_in "app_name", :with => "new app"
      click_button "Add App"

      page.should have_content("App was successfully created")
    end
  end
end
