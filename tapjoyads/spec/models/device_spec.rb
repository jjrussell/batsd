require 'spec_helper'

describe Device do
  describe "#handle_sdkless_click!" do
    before :each do
      fake_the_web

      app = Factory :app
      @offer = app.primary_offer
      @device = Factory :device
      @now = Time.zone.now
    end

    context "when an SDK-less app offer is clicked" do
      before :each do
        @offer.device_types = "[\"android\"]"
        @offer.sdkless = true
        @offer.save
        @device.handle_sdkless_click!(@offer, @now)
      end

      it "sets key for the target app in sdkless_clicks column of the device model to the app's app store ID" do
        @device.sdkless_clicks.should have_key @offer.third_party_data
      end

      it "adds the click timestamp to the target app's entry in sdkless_clicks" do
        @device.sdkless_clicks[@offer.third_party_data]['click_time'].should == @now.to_i
      end

      it "adds the target app's ID to the entry in sdkless_clicks" do
        @device.sdkless_clicks[@offer.third_party_data]['item_id'].should == @offer.item_id
      end
    end

    context "when a non-SDK-less app offer is clicked" do
      before :each do
        @offer.sdkless = false
        @offer.save
        @device.handle_sdkless_click!(@offer, @now)
      end

      it "doesn't add anything to the sdkless_clicks column of the device model" do
        @device.sdkless_clicks.should_not have_key @offer.third_party_data
      end
    end
  end
end