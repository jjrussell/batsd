module DashboardHelpers

  def capybara_register
    visit "/dashboard"
    click_link "Register now."
    fill_in "Email Address", :with => "jeff@dickey.xxx"
    fill_in "Company Name", :with => "Tapjoy"
    fill_in "Password", :with => "password"
    fill_in "Confirm Password", :with => "password"
    select "United States", :from => "Country"
    check "user_terms_of_service"
    click_button "Create Account"
  end

  def capybara_dashboard_login
    partner = Factory(:partner)
    app = Factory(:app, :partner => partner)
    user = Factory(:user, :partners => [partner])

    visit '/dashboard'
    fill_in 'Email Address', :with => user.username
    fill_in 'Password', :with => user.password
    click_button 'Log in'
  end
end
