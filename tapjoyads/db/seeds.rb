user_role = UserRole.create(:name => 'admin')
UserRole.create(:name => 'tools_user')

user = User.create(:username => 'testerman', :email => 'test@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')

RoleAssignment.create(:user => user, :user_role => user_role)

partner = Partner.create(:contact_name => 'test partner')

PartnerAssignment.create(:user => user, :partner => partner)

app = App.create(:partner => partner, :name => 'test app', :description => 'test description', :platform => 'iphone', :store_id => '00000000', :price => 99)
