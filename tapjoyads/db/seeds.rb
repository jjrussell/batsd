admin_role = UserRole.create(:name => 'admin')
tools_user_role = UserRole.create(:name => 'tools_user')
agency_role = UserRole.create(:name => 'agency')
partner_role = UserRole.create(:name => 'partner')

admin_user = User.create(:username => 'admin', :email => 'admin@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
tools_user = User.create(:username => 'tools_user', :email => 'tools_user@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
agency_user = User.create(:username => 'agency', :email => 'agency@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
partner_user = User.create(:username => 'partner', :email => 'partner@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')

RoleAssignment.create(:user => admin_user, :user_role => admin_role)
RoleAssignment.create(:user => tools_user, :user_role => tools_user_role)
RoleAssignment.create(:user => agency_user, :user_role => agency_role)
RoleAssignment.create(:user => partner_user, :user_role => partner_role)

partner = Partner.create(:contact_name => 'test partner')

PartnerAssignment.create(:user => partner_user, :partner => partner)

app = App.create(:partner => partner, :name => 'test app', :description => 'test description', :platform => 'iphone', :store_id => '00000000', :price => 99)
