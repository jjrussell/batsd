require 'rubygems'
require 'spork'

Spork.prefork do
  require 'pry'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'capybara/rspec'
  require 'factory_girl'
  require 'authlogic/test_case'
  require 'hpricot'

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    config.include(SpecHelpers)
    config.include(DashboardHelpers)
    config.include(Authlogic::TestCase)
    config.before(:each) do
      Resolv.stub!(:getaddress=>'1.1.1.1')
      RightAws::SdbInterface.stub!(:new => FakeSdb.new)
      SimpledbResource.reset_connection
      AWS::S3.stub!(:new => FakeS3.new)
      Sqs.stub(:send_message)
    end
  end
end

Spork.each_run do
end
