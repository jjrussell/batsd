When /^I go to the marketplace$/ do
  visit '/games'
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content(text)
end
