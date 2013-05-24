@javascript @tapjoy_marketer
Feature: Survey Offer
  As a Tapjoy marketer
  I want users to complete surveys
  So that I can gather user data

Scenario: Using the "new survey offer" form
  When I view the form to create a new survey
  Then I should be able to set the "Name"
  And I should be able to set the "Bid"
  And I should be able to upload an "Icon"
  And I should be able to add a "freeform text" question
  And I should be able to add a "radio button" question
  And I should be able to add possible answers to that question
  And I should be able to add a "dropdown" question
  And I should be able to add possible answers to that question
  And I should be able to remove a question
  And I should be able to save the survey

Scenario: Viewing the survey from the dashboard
  Given I have created a survey
  When I view the list of surveys
  Then I should see a link with the name of the survey that goes to the offer detail page
  And I should see a list of the survey's questions
  And I should see a link to the survey's offerwall view
  And I should see a link to enable the survey
  And I should see a link to edit the survey
  And I should see a link to remove the survey

Scenario: Seeing all responses for a question when editing
  Given I have created a survey with a "radio button" question
  And the question has 3 answers
  When I visit the "edit survey" page
  Then the question should have 3 responses

Scenario: Modifying the bid from the survey edit page
  Given I have created a survey with a bid of "$1.00"
  When I visit the "edit survey" page
  And I fill in "Bid" with "$2.00"
  And I press "Update Survey offer"
  Then the bid should be "$2.00"

Scenario: Modifying the bid from the offer edit page
  Given I have created a survey with a bid of "$1.00"
  When I visit the "statz edit offer" page
  And I fill in "Bid" with "$3.00"
  And I press "Save Changes"
  Then the bid should be "$3.00"

Scenario: Adding questions from an existing survey
  Given I have created a survey with 3 questions
  When I visit the "edit survey" page
  Then I should be able to remove an existing question

# WIP because it works, but times out causing ci failures
@wip
Scenario: Removing questions from an existing survey
  Given I have created a survey with 3 questions
  When I visit the "edit survey" page
  Then I should be able to add a new question

Scenario: Specifying the icon
  When I fill in the form to create a new survey
  And I attach an icon
  And I submit the new survey form
  Then the survey should use that icon

Scenario: Viewing via the offerwall
  Given I have created a survey with 3 questions
  When I view the list of surveys
  When I click "Offerwall view"
  Then I should see what the survey looks like on the offerwall

Scenario: Enabling
  Given I have created a survey
  When I view the list of surveys
  Then I should be able to enable the survey

Scenario: Disabling a survey
  Given I have enabled a survey
  When I view the list of surveys
  Then I should be able to disable the survey

Scenario: Removing a survey
  Given I have created a survey
  When I view the list of surveys
  Then I should be able to remove the survey from the system

# @partner
# Scenario: Viewing survey results

# @gamer
# Scenario: Filling in a survey on the offerwall

# @gamer
# Scenario: Filling in a survey in app

# @gamer
# Scenario: Failing to answer questions while filling in a survey

