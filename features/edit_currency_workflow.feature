@javascript @partner @stub_resolvable_host
Feature: Warn of the impact of modifying a currency
  As a partner
  I want to be warned of the impact of modifying a virtual currency
  So that I can make informed decisions about how to change my currencies


Background:
  Given I have an unmanaged currency

Scenario: Modifying a Tapjoy-disabled currency
  Given the currency is not tapjoy-enabled
  When I visit the "edit currency" page
  And I change the conversion rate
  And I change the callback URL
  And I press "Update Currency"
  Then I should not see a confirmation of the change
  And I should be on the "show currency" page
  And I should not see a notice regarding the change

Scenario: Changing the conversion rate
  When I visit the "edit currency" page
  And I change the conversion rate
  And I press "Update Currency"
  Then I should see a confirmation of the change
  When I accept the confirmation 
  Then I should be on the "show currency" page
  And I should see a notice regarding the change
  And the conversion rate should have changed

Scenario: Changing the callback URL
  When I visit the "edit currency" page
  And I change the callback URL
  And I press "Update Currency"
  Then I should see a confirmation of the change
  When I accept the confirmation 
  Then I should be on the "show currency" page
  And I should see a notice regarding the change
  And the callback URL should have changed

Scenario: Changing a safe attribute
  When I visit the "edit currency" page
  And I change the currency name
  And I press "Update Currency"
  Then I should not see a confirmation of the change
  And I should be on the "show currency" page
  And I should not see a notice regarding the change

