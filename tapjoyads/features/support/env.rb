require 'rubygems'
require 'spork'

Spork.prefork do
  require 'cucumber/rails'

  Capybara.default_selector = :css
  ActionController::Base.allow_rescue = false
  DatabaseCleaner.strategy = :transaction
  Cucumber::Rails::Database.javascript_strategy = :truncation

  Resolv.stubs(:getaddress).returns('1.1.1.1')
  RightAws::SdbInterface.stubs(:new).returns(FakeSdb.new)
  SimpledbResource.reset_connection
  AWS::S3.stubs(:new).returns(FakeS3.new)
end

Spork.each_run do
end
