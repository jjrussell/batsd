require 'rubygems'
require 'spork'

Spork.prefork do
  require 'pry'
  require 'cucumber/rails'
  require 'authlogic/test_case'
  require 'database_cleaner'
  require 'database_cleaner/cucumber'

  Capybara.default_selector = :css
  ActionController::Base.allow_rescue = false
  DatabaseCleaner.strategy = :truncation
  Cucumber::Rails::Database.javascript_strategy = :truncation

  Resolv.stubs(:getaddress).returns('1.1.1.1')
  RightAws::SdbInterface.stubs(:new).returns(FakeSdb.new)
  SimpledbResource.reset_connection
  AWS::S3.stubs(:new).returns(FakeS3.new)
end

Spork.each_run do
end
