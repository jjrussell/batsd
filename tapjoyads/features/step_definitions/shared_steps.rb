Given /^I go to "([^"]*)"$/ do |text|
  click_link text
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content(text)
end

When /^show me the page$/ do
  save_and_open_page
end

When /^I press "([^"]*)"$/ do |text|
  click_button text
end
