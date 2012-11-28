require 'spec_helper'

describe Api::Client::AdsController do
  it_should_behave_like 'a pageable resource'

  context "considering permissions" do
    it "should return no apps if the user doesn't have read permissions" do
      @controller.stub(:can?).and_return(false)
      get :index
      assigns(:offers).should be_nil
    end

    it "should pass through if the user has read permissions" do
      @controller.stub(:can?).and_return(true)
      get :index
      assigns(:offers).should_not be_nil
    end
  end
end
