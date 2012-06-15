shared_context "logged in as an account manager" do
  let(:user) { FactoryGirl.create(:account_mgr_user) }

  before(:each) do
    activate_authlogic
    login_as(user)
  end
end
