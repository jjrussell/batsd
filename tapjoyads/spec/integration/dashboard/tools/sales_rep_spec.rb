require 'spec_helper'

describe 'sales_reps' do
  before :each do
    capybara_dashboard_admin_login
    @offer = Factory(:app).primary_offer
    @account_manager = Factory(:account_mgr_user)
    visit statz_path(@offer)
    click_link "[Sales Reps]"
  end

  it 'adds a sales rep' do
    click_link "Add sales rep"
    select @account_manager.email, :from => 'Sales rep'
    fill_in 'Start date', :with => '01/01/2001'
    click_button "Add sales rep"

    page.should have_content "Success: Added sales rep #{@account_manager.email}"
    page.should have_content "01/01/2001"
  end

  it 'edits a sales rep' do
    # Add the sales rep first
    click_link "Add sales rep"
    select @account_manager.email, :from => 'Sales rep'
    fill_in 'Start date', :with => '01/01/2001'
    click_button "Add sales rep"

    # now edit
    click_link "Edit"
    fill_in 'Start date', :with => '02/01/2001'
    fill_in 'End date', :with => '03/01/2001'
    click_button "Update sales rep"

    page.should have_content "Success: Updated sales rep #{@account_manager.email}"
    page.should have_content "02/01/2001"
    page.should have_content "03/01/2001"
  end
end
