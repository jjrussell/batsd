shared_context "logged in as user type" do |user_type|
  user_type_name = (user_type.to_s + "_user").to_sym
  let(:user) { user = FactoryGirl.create(user_type_name)
               FactoryGirl.create(:partner, :pending_earnings => 10000, :balance => 10000, :users => [user])
               user }

  before(:each) do
    activate_authlogic
    login_as(user)
  end
end
