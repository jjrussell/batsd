@javascript @account_manager
Feature: Offer Icon Overriding
  As an account manager
  I want to be able to override an offer's icon
  And remove it

Background:
  Given I have an app

Scenario: Overriding the icon from the offer edit page
  When I visit the "statz edit offer" page
  And I attach the icon
  And I submit the icon form
  Then the icon image should change to the new icon

Scenario: Reverting back to the default icon
  Given I have uploaded an icon
  When I visit the "statz edit offer" page
  And I remove the icon
  Then the icon image should change to the default
