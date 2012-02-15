require 'spec/spec_helper'

describe Games::MyAppsController do
  describe "#index" do

    context "logged in" do
      before :each do
        activate_authlogic
      end
      
      context "has selected device" do
      end

      context "no selected device" do
      end
    end

    context "not logged in" do
      it "redirects to homepage controller" do
        get "index"
        
        response.should redirect_to(games_login_url(:path=>games_my_apps_path))
      end
    end

  end
end
