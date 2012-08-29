@javascript @tapjoy_marketer
Feature: Video Cache Controls
  As a tapjoy marketer
  I want to control how videos are cached by the SDK
  So that I can provide my users with the best experience

Background:
  Given I have an app

Scenario: Using the "video caching options" form
  When I view the form to modify an app's caching options
  Then the "Enable Video Ads" field should be checked
  And I should be able to check the "Cache over WiFi" field
  And I should be able to check the "Cache over 3G" field
  And I should be able to check the "Automatic Caching" field
  And I should be able to check the "Stream over 3G" field
  And I should be able to save the form
  And I should see a message after the AJAX request

Scenario: Disabling "Video Ads"
  When I view the form to modify an app's caching options
  And I uncheck the "Enable Video Ads" field
  Then I should not be able to check the "Cache over WiFi" field
  And I should not be able to check the "Cache over 3G" field
  And I should not be able to check the "Automatic Caching" field
  And I should not be able to check the "Stream over 3G" field
  And I should be able to save the form

Scenario: Enabling "Automatic Caching"
  When I view the form to modify an app's caching options
  And I check the "Cache over WiFi" field
  And I check the "Cache over 3G" field
  Then I should be able to check the "Automatic Caching" field
  And I should be able to check the "Stream over 3G" field
  And I should be able to save the form

Scenario: Disabling "Cache over WiFi"
  When I view the form to modify an app's caching options
  And I uncheck the "Cache over WiFi" field
  And I check the "Cache over 3G" field
  Then I should be able to check the "Automatic Caching" field
  And I should be able to check the "Stream over 3G" field
  And I should be able to save the form

Scenario: Disabling "Cache over 3G"
  When I view the form to modify an app's caching options
  And I check the "Cache over WiFi" field
  And I uncheck the "Cache over 3G" field
  Then I should be able to check the "Automatic Caching" field
  And I should be able to check the "Stream over 3G" field
  And I should be able to save the form

Scenario: Disabling all video caching
  When I view the form to modify an app's caching options
  And I uncheck the "Cache over WiFi" field
  And I uncheck the "Cache over 3G" field
  Then I should not be able to check the "Automatic Caching" field
  And I should be able to check the "Stream over 3G" field
  And I should be able to save the form
