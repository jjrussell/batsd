require 'spec_helper'

describe 'device_info' do
  before :each do
    capybara_dashboard_admin_login
    @device = Device.new(:key => FactoryGirl.generate(:udid), :consistent => true)
    currency_id = FactoryGirl.create(:currency).id
    advertiser_app_id = FactoryGirl.create(:app).id
    @click = Click.new(:key => FactoryGirl.generate(:guid), :consistent => true)
    @click.udid = @device.id
    @click.currency_id = currency_id,
    @click.advertiser_app_id = advertiser_app_id,
    @click.publisher_app_id = Currency.find(currency_id).app.id,
    @click.offer_id = App.find(advertiser_app_id).offers.first.id,
    @click.clicked_at = Time.now - 1.day
    @click.save

    @account_manager = FactoryGirl.create(:account_manager)
    visit tools_path
    click_link "Device Info & Unresolved clicks"
  end

  it 'should show recent clicks' do
    fill_in "udid", :with => @device.id
    click_button "Find"
    # wait until device_info switched to use device.recent_clicks
    #page.should have_content 'Installed Apps'
    #page.should have_content 'Clicks (1)'
    #page.should have_content "Click ID: #{@click.id}"
  end

end
