Given /^I go to "([^"]*)"$/ do |text|
  click_link text
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content(text)
end

When /^show me the page$/ do
  save_and_open_page
end

When /^I check "([^"]*)"$/ do |text|
  check text
end

When /^I fill in "([^"]*)" with "([^"]*)"$/ do |name, text|
  fill_in name, :with => text
end

When /^I press "([^"]*)"$/ do |text|
  click_button text
end

When /^I should be at the homepage$/ do
  current_path.should == '/'
end

When /^I wait (\d+) seconds$/ do |seconds|
  sleep(seconds.to_i)
end
