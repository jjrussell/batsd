require 'spec_helper'

describe Dashboard::ActivitiesController do
  before :each do
    activate_authlogic
    user = FactoryGirl.create(:user)
    login_as(user)
  end

  describe 'index' do
    it 'gets activity log' do
      params = {:user => "someone@tapjoy.com",
                :object => "56a2cbef-80c3-46fd-ad83-fd9b9dc9ac74",
                :request_id => "",
                :partner_id => "c533dc9c-6f07-4a74-bea3-a17aa608c6cb",
                :start_date => "2012-05-01",
                :end_date => "2012-05-11",
                :object_type => "Offer",
                :field => "impression",

                }
      get(:index, params)
    end
  end
end
