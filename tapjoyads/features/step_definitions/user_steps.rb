Given /^I am logged in with a partner$/ do
  user = Factory(:user)
  partner = Factory(:partner)
  user.partners << partner
  app = Factory(:app, :partner => partner)
  UserSession.create(user)
  visit '/dashboard'
  fill_in 'Email Address', :with => user.username
  fill_in 'Password', :with => user.password
  click_button 'Log in'
end
