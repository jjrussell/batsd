admin_role = UserRole.create(:name => 'admin')
payops_role = UserRole.create(:name => 'payops')
agency_role = UserRole.create(:name => 'agency')
partner_role = UserRole.create(:name => 'partner')
executive_role = UserRole.create(:name => 'executive')
account_mgr_role = UserRole.create(:name => 'account_mgr')

admin_user = User.create(:username => 'admin', :email => 'admin@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
payops_user = User.create(:username => 'payops', :email => 'payops@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
agency_user = User.create(:username => 'agency', :email => 'agency@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
partner_user = User.create(:username => 'partner', :email => 'partner@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
executive_user = User.create(:username => 'executive', :email => 'executive@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')
account_mgr_user = User.create(:username => 'account_mgr', :email => 'account_mgr@tapjoy.com', :password => 'asdf', :password_confirmation => 'asdf')

RoleAssignment.create(:user => admin_user, :user_role => admin_role)
RoleAssignment.create(:user => payops_user, :user_role => payops_role)
RoleAssignment.create(:user => agency_user, :user_role => agency_role)
RoleAssignment.create(:user => partner_user, :user_role => partner_role)
RoleAssignment.create(:user => executive_user, :user_role => executive_role)
RoleAssignment.create(:user => account_mgr_user, :user_role => account_mgr_role)

partner = Partner.create(:contact_name => 'test partner')

PartnerAssignment.create(:user => partner_user, :partner => partner)

app = App.create(:partner => partner, :name => 'test app', :description => 'test description', :platform => 'iphone', :store_id => '00000000', :price => 99)
