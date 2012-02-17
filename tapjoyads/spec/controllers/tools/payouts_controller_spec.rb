require 'spec/spec_helper'

describe Tools::PayoutsController do
  integrate_views

  before :each do
    activate_authlogic
  end

  before :each do
    @user = Factory :admin
    @partner = Factory(:partner, :users => [@user])
    login_as @user
  end

  it 'should render payouts page' do
    get :index
  end
end
