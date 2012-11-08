require 'spec_helper'

describe Dashboard::Tools::DeviceBanListsController do
  before :each do
    activate_authlogic
    cs_mgr = FactoryGirl.create(:customer_service_manager)
    login_as(cs_mgr)
    @device = Device.new
    @device.save
    @click = Click.new
    @click.udid = @device.id
    @click.save
    @ban_reason = "Fraud"
  end

  describe "#create" do
    it "should redirect back to the index page after banning device(s)" do
      post(:create, :target_id => @device.id, :ban_reason => @ban_reason)
      response.should redirect_to tools_device_ban_lists_path
    end

    it "should flash a success message when passed a Device ID" do
      post(:create, :target_id => @device.id, :ban_reason => @ban_reason)
      flash[:notice].should eq "You've successfully banned a device."
    end

    it "should flash a success message when passed a Click ID" do
      post(:create, :target_id => @click.id, :ban_reason => @ban_reason)
      flash[:notice].should eq "You've successfully banned a device."
    end
  end
end
