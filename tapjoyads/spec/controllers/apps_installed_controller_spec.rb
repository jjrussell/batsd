require 'spec/spec_helper'

describe AppsInstalledController do
  integrate_views

  before :each do
    fake_the_web
    Sqs.stubs(:send_message)
  end

  context '#index' do
    before :each do
      # Build valid parameters array
    end

    context 'without required parameters' do
      it "returns an error when udid is omitted"

      it "returns an error when app_id is omitted"

      it "returns an error when library_version is omitted"

      it "returns an error when sdk_type is omitted"

      it "returns an error when verifier is omitted"

      it "returns an error when package_names is omitted"
    end

    context 'with required parameters' do
      it "returns an error when verifier is invalid"

      it "returns an error if API does not support SDK-less clicks"

      it "creates click models for sdkless clicks stored on device model"

      it "adds sdkless clicks to SQS conversion queue"

      it "removes queued sdkless clicks from device model"

      it "creates a web request for this apps_installed call"
    end
  end
end
