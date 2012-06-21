shared_context "logged in as customer service user" do
  let(:user) { user = FactoryGirl.create(:customer_service_user)
               FactoryGirl.create(:partner, :pending_earnings => 10000, :balance => 10000, :users => [user])
               user }

  before(:each) do
    activate_authlogic
    login_as(user)
  end
end
