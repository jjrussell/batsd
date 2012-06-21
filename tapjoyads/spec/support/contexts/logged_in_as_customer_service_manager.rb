shared_context "logged in as customer service manager" do
  let(:user) { user = FactoryGirl.create(:customer_service_manager)
              FactoryGirl.create(:partner, :pending_earnings => 10000, :balance => 10000, :users => [user])
              user }

  before(:each) do
    activate_authlogic
    login_as(user)
  end
end
