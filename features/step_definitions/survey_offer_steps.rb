When /^I view the form to create a new survey$/ do
  visit '/dashboard/tools/survey_offers/new'
end

When /^I fill in the form to create a new survey$/ do
  step "I view the form to create a new survey"
  step "I fill in \"Name\" with \"Bridge Survey\""
  @name = 'Bridge Survey'
  step "I fill in \"Bid\" with \"$2.00\""
end

Then /^I should be able to set the "(.*?)"$/ do |field|
  fill_in_survey_field(field)
end

Then /^I should be able to upload an? "(.*?)"$/ do |field|
  attach_file(field, file_for(field))
end

Then /^I should be able to add a "(.*?)" question$/ do |format|
  expect {click_button "Add Question"}.to change{question_count}.by(1)
  fill_in_question(last_question, format)
end

Then /^I should be able to add possible answers to that question$/ do
  fill_in_answers(last_question, @type)
end

Then /^I should be able to remove a question$/ do
  click_button "Add Question"
  expect do
    within(last_question) do
      click_button 'Remove'
    end
  end.to change{ question_count }.by(-1)
end

Then /^I should be able to save the survey$/ do
  click_button 'Create Survey offer'
  current_path.should == '/dashboard/tools/survey_offers'
  page.body.should =~ /Survey offer created successfully/
  page.body.should =~ /#{SURVEY_FIELDS["Name"]}/

  # OK, this part sucks.
  @survey = SurveyOffer.find_by_name("Bridge Survey")
  @survey.bid.should == 100
  @survey.questions.count.should == 3
end

Given /^I have created a survey with a bid of "(.*?)"$/ do |amount|
  @survey = FactoryGirl.create(:survey_offer, :bid => amount.gsub(/[^\d]+/, '').to_i, :partner => @partner)
  @offer = @survey.primary_offer
end

Given /^I have created a survey with (\d+) questions$/ do |n|
  @survey = FactoryGirl.create(:survey_offer, :partner => @partner)
  n.to_i.times { FactoryGirl.create(:survey_question, :survey_offer => @survey) }
  @survey.save!
end

When /^I fill in "(.*?)" with "(.*?)"$/ do |field, value|
  fill_in field, :with => value
end

When /^I press "(.*?)"$/ do |button|
  click_button button
end

Then /^the survey should use that icon$/ do
  true
  # TODO: Make this real
  # @survey = SurveyOffer.find_by_name(@name)
  # survey_icon_bytes = Net::HTTP.get_response()
  # #Net::HTTP.get_response(URI.parse(@survey.get_icon_url)) #== File.open(file_for("Icon")).read
end

Given /^I have created a survey$/ do
  @survey = FactoryGirl.create(:survey_offer, :partner => @partner)
  @offer = @survey.primary_offer
end

When /^I view the list of surveys$/ do
  visit '/dashboard/tools/survey_offers'
end

Then /^the bid should be "(.*?)"$/ do |amount|
  @survey.reload
  @survey.bid.should == amount.gsub(/\D+/, '').to_i
end

Then /^I should be able to remove an existing question$/ do
  expect do
    within(last_question) do
      click_button "Remove"
    end
    click_button "Update Survey offer"
  end.to change{@survey.questions.count}.by(-1)
end

Then /^I should be able to add a new question$/ do
  expect do
    click_button "Add Question"
    fill_in_textfield_question(last_question)
    click_button "Update Survey offer"
  end.to change{@survey.questions.count}.by(1)
end

Then /^I should see what the survey looks like on the offerwall$/ do

  @survey.questions.each do |question|
    node = find(".question .number", :text => question.position.to_s)
    # TODO: Robustify
#   page.should have_checkbox '#terms'
#   page.should have_button "Submit"
#   fail "submit button should be inactive when tos is unchecked"
#   fail "submit button should be active   when tos is checked"
    # node.should have_appropriate_response_fields_for(question)
  end
end

Then /^I should be able to enable the survey$/ do
  click_link "Enable"
  page.driver.browser.switch_to.alert.accept
end

Then /^I should be able to disable the survey$/ do
  click_link "Disable"
end

Given /^I have enabled a survey$/ do
  @survey = FactoryGirl.create(:survey_offer, :partner => @partner)
  visit '/dashboard/tools/survey_offers'
  click_link "Enable"
  page.driver.browser.switch_to.alert.accept
end

Then /^I should be able to remove the survey from the system$/ do
  click_link "Remove"
  page.driver.browser.switch_to.alert.accept
  visit '/dashboard/tools/survey_offers' #
  @survey.reload
  @survey.should be_hidden
end

Then /^the question should have (\d+) responses$/ do |n|
  # TODO: Make this suck less
  page.find('.question_responses input').value.split(';').length.should == n.to_i
end

Then /^I should see a link (.*)$/ do |description|
  text, destination, verb = link_for(description)
  link = page.find("a[href='#{destination}']", :text => text)
  link.should be_present
  (link['data-method'].should == verb) if verb
end

Then /^I should see a list of the survey's questions$/ do
  @survey.questions.each do |question|
    page.find('li', :text => question.text).should be_present
  end
end

When /^I attach an icon$/ do
  attach_file("Icon", file_for("Icon"))
end

When /^I submit the new survey form$/ do
  click_button "Create Survey offer"
end

When /^I click "(.*?)"$/ do |text|
  click_link text
end

Given /^I have created a survey with a "(.*?)" question$/ do |format|
  @survey   = FactoryGirl.create(:survey_offer, :partner => @partner)
  @question = FactoryGirl.create(:survey_question,
    :survey_offer => @survey,
    :format       => internalize(format),
    :responses    => "answer1;answer2;answer3"
  )
  @survey.reload
end

Given /^the question has (\d+) answers$/ do |n|
  n.to_i.times { @question.responses << "some answer" }
  @question.save!
end
