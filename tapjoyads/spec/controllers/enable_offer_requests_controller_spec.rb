require 'spec/spec_helper'

describe EnableOfferRequestsController do
  before :each do
    activate_authlogic
  end

  it 'is not able to submit a request' do
    user = Factory(:user)
    partner = Factory(:partner, :users => [ user ])
    app = Factory(:app, :partner => partner)
    offer = app.primary_offer
    login_as(user)

    offer.enable_offer_requests.should be_blank

    post :create, :enable_offer_request => { :offer_id => offer.id }

    response.should be_redirect
    offer.reload.enable_offer_requests.first.status.should == 0
  end
end
