# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a 
# newer version of cucumber-rails. Consider adding your own code to a new file 
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

require 'cucumber/rails'

# require 'authlogic/test_case'
# World(Authlogic::TestCase)
# ApplicationController.skip_before_filter :activate_authlogic

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css
# Capybara.app_host = "http://localhost:3000"
# Capybara.default_driver = :selenium

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how 
# your application behaves in the production environment, where an error page will 
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

# Fix for an error with the onchange event handler in Capybara:
# https://groups.google.com/forum/?fromgroups#!topic/ruby-capybara/LZ6eu0kuRY0
class Capybara::Selenium::Node < Capybara::Driver::Node
  def set(value) 
    if tag_name == 'textarea' or (tag_name == 'input' and %w(text password hidden file).include?(type)) 
      keys = [] 
      # delete existing values from field.. does not use node.clear as this trigger onchange event.. 
      keys << "\b" * native[:value].size if native[:value] 
      keys << value.to_s 
      native.send_keys(keys) 
      # execute onchange script after update is finished if it exists.. 
      native.bridge.executeScript("$('#{native[:id]}').onchange()") if native[:onchange] 

    elsif tag_name == 'input' and type == 'radio' 
      native.click 
    elsif tag_name == 'input' and type == 'checkbox' 
      native.click if native.attribute('checked') != value 
    end 
  end 
end 


Before('@tapjoy_marketer') do
  @partner ||= FactoryGirl.create(:partner,      :id => TAPJOY_PARTNER_ID)
  @user    ||= FactoryGirl.create(:partner_user, :current_partner => @partner)
  @user.user_roles << UserRole.find_or_create_by_name('admin', :employee => true)

  visit '/login'
  fill_in 'Email Address', :with => @user.email
  fill_in 'Password', :with => 'asdf'
  click_button 'Log in'
  # TODO: Figure out a better way to fake the password
  # activate_authlogic
  # UserSession.create!(@user)
end
# You may also want to configure DatabaseCleaner to use different strategies for certain features and scenarios.
# See the DatabaseCleaner documentation for details. Example:
#
#   Before('@no-txn,@selenium,@culerity,@celerity,@javascript') do
#     # { :except => [:widgets] } may not do what you expect here
#     # as tCucumber::Rails::Database.javascript_strategy overrides
#     # this setting.
#     DatabaseCleaner.strategy = :truncation
#   end
#
#   Before('~@no-txn', '~@selenium', '~@culerity', '~@celerity', '~@javascript') do
#     DatabaseCleaner.strategy = :transaction
#   end
#

# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
Cucumber::Rails::Database.javascript_strategy = :truncation

