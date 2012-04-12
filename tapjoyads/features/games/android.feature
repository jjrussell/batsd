Feature: Android
  In order to view the marketplace
  As an Android user
  I should be able to access the marketplace

  Scenario: Not logged in
    Given I visited the android page with a valid device and app
    When I go to "Sign Up"
    Then I should be redirected to the marketplace login screen
