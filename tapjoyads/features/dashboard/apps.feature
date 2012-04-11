Feature: Apps
  In order to use tapjoy in my app
  As a partner
  I should be able to add my app on the dashboard

  Scenario: Adding an app as a new user
    When I register for tapjoy
    And I fill in "app_name" with "newapp"
    And I press "Add App"
    Then I should see "App was successfully created"

  Scenario: Adding a second app
    Given I am logged in with a partner
    And I go to "Apps"
    And I fill in "app_name" with "newapp"
    And I press "Add App"
    And I fill in "app_name" with "newapp"
    And I press "Add App"
    Then I should see "App was successfully created"

  Scenario: Updating rewarded installs
    Given I am logged in with a partner
    And I go to "Apps"
    And I go to "Rewarded Installs"
    When I check "Enable Installs"
    And I press "Update"
    Then I should see "Your offer was successfully updated."
