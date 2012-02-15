require 'spec_helper'

describe Games::MyAppsController do

  #Delete these examples and add some real ones
  it "should use Games::MyAppsController" do
    controller.should be_an_instance_of(Games::MyAppsController)
  end


  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'show'" do
    it "should be successful" do
      get 'show'
      response.should be_success
    end
  end
end
