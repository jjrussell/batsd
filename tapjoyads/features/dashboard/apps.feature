Feature: Apps
  In order to use tapjoy in my app
  As a partner
  I should be able to add my app on the dashboard

  Scenario: Adding an app as a new user
    When I register for tapjoy
    And I fill out the add app form
    And I press "Add App"
    Then I should see "App was successfully created"

  Scenario: Adding a second app
    Given I am logged in with a partner
    And I go to "Apps"
    When I fill out the add app form
    And I press "Add App"
    And I fill out the add app form
    And I press "Add App"
    Then I should see "App was successfully created"
