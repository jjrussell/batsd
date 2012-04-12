Feature: Marketplace
  In order to find out about new apps
  As a gamer
  I should be able to see the marketplace

  Scenario: Visiting home page
    Given I am at the marketplace homepage
    Then I should see "Tapjoy Marketplace"

  # not working right now
  #@javascript
  #Scenario: Registering
    #Given I am at the marketplace homepage
    #And freeze
    #When I go to "Sign Up"
    #And I fill out the games signup form
    #And I wait 5 seconds
    #Then I should be at the homepage
