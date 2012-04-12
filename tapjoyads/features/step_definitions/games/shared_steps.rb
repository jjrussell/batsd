Given /^I am at the marketplace homepage$/ do
  visit '/games'
end

When /^I fill out the games signup form$/ do
  fill_in "gamer_nickname", :with => "dickeyxxx"
  select "August", :from => "date_month"
  select "6", :from => "date_day"
  select "1986", :from => "date_year"
  fill_in "gamer_email", :with => 'jeff@dickey.xxx'
  fill_in "gamer_email", :with => 'jeff@dickey.xxx'
  fill_in "gamer_password", :with => 'password'
  page.execute_script("$('#platform_android').click();
                       $('#gamer_terms_of_service').click();")
  click_button "Next"
end

Then /^I should be redirected to the marketplace login screen$/ do
  current_path.should == '/games/gamer/new'
end
