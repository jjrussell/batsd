require 'spec/spec_helper'

describe Tools::GamersController do
  before :each do
    activate_authlogic
  end

  before :each do
    @user = Factory :admin
    @partner = Factory(:partner, :users => [@user])
    @app = Factory(:app, :partner => @partner)
    login_as @user
  end
end
