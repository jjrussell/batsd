Given /^I have an unmanaged currency$/ do
  @app      = FactoryGirl.create(:app, :partner => @partner)
  @currency = FactoryGirl.create(:unmanaged_currency, :app => @app, :partner => @app.partner)
end

Given /^the currency is not tapjoy\-enabled$/ do
  @currency.tapjoy_enabled = false
  @currency.save!
end

When /^I change the (.*?)$/ do |field_name|
  field = find(selector_for "#{field_name} field")
  @original_value = field.value
  field.set(mutator_for(field_name))
end

Then /^I should see a confirmation of the change$/ do
  expect{@confirmation = page.driver.browser.switch_to.alert}.not_to raise_exception(Selenium::WebDriver::Error::NoAlertPresentError)
end

Then /^I should not see a confirmation of the change$/ do
  expect{page.driver.browser.switch_to.alert}.to raise_exception(Selenium::WebDriver::Error::NoAlertPresentError)
end

When /^I accept the confirmation$/ do
  @confirmation.accept
end

Then /^I should be on the "(.*?)" page$/ do |p|
  current_path.should == path_for(p)
end

Then /^I should see a notice regarding the change$/ do
  find('#flash_warning').should have_content('made a change that could negatively impact')
end

Then /^I should not see a notice regarding the change$/ do
  find('#flash_warning').should_not have_content('made a change that could negatively impact')
end

Then /^the (.*?) should have changed$/ do |field_name|
  current_value = find(selector_for "#{field_name} field").value
  current_value.should_not == @original_value.to_s
end
