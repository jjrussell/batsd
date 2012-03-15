require 'spec/spec_helper'

describe 'layouts/tabbed.html.haml' do
  context 'with a partner user' do
    before :each do
      user = Factory :partner_user
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      controller.stubs(:current_partner).returns(user.current_partner)
      template.stubs(:current_partner).returns(user.current_partner)
      current_partner_app_offers = user.current_partner.offers.visible.client_facing_app_offers.sort_by{|app| app.name.downcase}
      controller.stubs(:current_partner_active_app_offers).returns(current_partner_app_offers.select(&:is_enabled?))
      template.stubs(:current_partner_active_app_offers).returns(current_partner_app_offers.select(&:is_enabled?))
      controller.stubs(:premier_enabled?).returns(true)
      template.stubs(:premier_enabled?).returns(true)
      render
    end

    it 'hides the link to the premier program' do
      response.should_not have_tag("a[href=?]", premier_path)
    end
  end

  context 'with a premier user' do
    before :each do
      user = Factory :premier_partner_user
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      controller.stubs(:current_partner).returns(user.current_partner)
      template.stubs(:current_partner).returns(user.current_partner)
      current_partner_app_offers = user.current_partner.offers.visible.client_facing_app_offers.sort_by{|app| app.name.downcase}
      controller.stubs(:current_partner_active_app_offers).returns(current_partner_app_offers.select(&:is_enabled?))
      template.stubs(:current_partner_active_app_offers).returns(current_partner_app_offers.select(&:is_enabled?))
      controller.stubs(:premier_enabled?).returns(true)
      template.stubs(:premier_enabled?).returns(true)
      render
    end

    it 'shows the link to the premier program' do
      response.should have_tag("a[href=?]", premier_path)
    end
  end
end
