Given /^I am logged in with a partner$/ do
  include Authlogic::TestCase
  activate_authlogic
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

When /^I register for tapjoy$/ do
  visit "/dashboard"
  click_link "Register now."
  fill_in "Email Address", :with => "jeff@dickey.xxx"
  fill_in "Company Name", :with => "Tapjoy"
  fill_in "Password", :with => "password"
  fill_in "Confirm Password", :with => "password"
  fill_in "Confirm Password", :with => "password"
  select "United States", :from => "Country"
  check "user_terms_of_service"
  click_button "Create Account"
end
