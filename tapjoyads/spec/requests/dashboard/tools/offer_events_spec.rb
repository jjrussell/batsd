require 'spec_helper'

describe 'offer_events' do
  before :each do
    capybara_dashboard_admin_login
    @offer_event = Factory(:offer_event)
    @account_manager = Factory(:account_mgr_user)
    click_link "Schedule Offer Events"
  end

  it 'edits an offer change' do
    click_link "Edit"
    fill_in 'Scheduled time', :with => '04/25/2022 10:00 PM'
    click_button "Save Event"

    page.should have_content "Updated Event for #{@offer_event.offer}"
    page.should have_content "04/25/2022 10:00 PM"
  end
end
