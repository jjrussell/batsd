shared_context "logged in as user with role" do |role|
  let(:user) { FactoryGirl.create(:user, :"with_#{role}_role") }

  before(:each) do
    activate_authlogic
    login_as(user)
  end
end
