shared_context "logged in as a partner" do
  let(:user) { FactoryGirl.create(:partner_user) }

  before(:each) do
    activate_authlogic
    login_as(user)
  end
end
