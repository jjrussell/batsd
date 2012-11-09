When /^I view the form to modify an app's caching options$/ do
  visit "/dashboard/apps/#{@app.id}/videos/options"
end

When /^I (un)?check the "(.*?)" field$/ do |un, field|
  ele = find_field(field)

  if un
    uncheck(field) if ele.checked?
  else
    check(field) unless ele.checked?
  end
end

Then /^I should (not )?be able to (un)?check the "(.*?)" field$/ do |nope, un, field|
  ele = find_field(field)

  if nope
    ele.should_not be_visible
  else
    if un
      uncheck(field) if ele.checked?
    else
      check(field) unless ele.checked?
    end
  end
end

Then /^the "(.*?)" field should be (un)?checked$/ do |field, un|
  if un
    find_field(field).should_not be_checked
  else
    find_field(field).should be_checked
  end
end

Then /^I should be able to save the form$/ do
  click_button('Save Changes')
end

Then /^I should see a message after the AJAX request$/ do
  wait_for_ajax
  page.should have_selector('.flash', :visible => true)
end

