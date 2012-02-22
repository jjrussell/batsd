require 'spec/spec_helper'

describe Games::MyAppsController do
  before :each do
    activate_authlogic
  end
  describe "#index" do

    context "logged in" do
      before :each do
        @user = Factory(:user)
        games_login_as(@user)
      end

      it "renders the my_apps view" do
        get "index"

        response.should render_template("index")
      end
      context "has selected device" do
      end

      context "no selected device" do
      end
    end

    context "not logged in" do
      it "redirects to homepage controller with path parameter" do
        get "index"

        response.should redirect_to(games_login_url(:path=>games_my_apps_path))
      end
    end

  end
end
