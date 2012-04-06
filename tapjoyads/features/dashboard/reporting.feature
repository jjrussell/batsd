Feature: Reporting
  In order to find more info about partners
  As a user with a partner
  I should be able to read reports

  Scenario: Getting to the reports
    Given I am logged in with a partner
    And I am on the dashboard
    When I visit the reporting tab
    Then I should see "Reporting for"
