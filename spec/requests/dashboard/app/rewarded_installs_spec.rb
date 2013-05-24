require 'spec_helper'

describe "App rewarded installs", :type => :request do

  setup :activate_authlogic

  describe "Updating rewarded installs" do
    it "enables installs" do
      capybara_dashboard_login

      visit '/dashboard/apps'
      click_link 'Rewarded Installs'
      check 'Enable Installs'
      click_button 'Update'

      page.should have_content('Your offer was successfully updated')
    end
  end
end
