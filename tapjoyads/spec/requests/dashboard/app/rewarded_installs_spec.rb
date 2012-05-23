require 'spec_helper'

describe "App rewarded installs", :type => :request do

  before :each do
    fake_the_web
    activate_authlogic
  end

  describe "Updating rewarded installs" do
    it "enables installs" do
      capybara_dashboard_login

      click_link 'Apps'
      click_link 'Rewarded Installs'
      check 'Enable Installs'
      click_button 'Update'

      page.should have_content('Your offer was successfully updated')
    end
  end
end
