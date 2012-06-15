shared_context "logged in as customer service" do
  let(:user) { FactoryGirl.create(:customer_service_user) }

  before(:each) do
    activate_authlogic
    login_as(user)
  end
end
