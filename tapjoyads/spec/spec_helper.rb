require 'rubygems'
require 'spork'

unless defined?(DeferredGarbageCollection)
  class DeferredGarbageCollection
    GC_THRESHOLD = 5.0

    def self.start
      GC.disable
      @@thread = Thread.new do
        loop do
          sleep GC_THRESHOLD
          GC.enable; GC.start; GC.disable
        end
      end
    end

    def self.stop
      Thread.kill(@@thread)
    end
  end
end

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
  require 'fake_memcached'
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    config.include(SpecHelpers)
    config.include(DashboardHelpers)
    config.include(Authlogic::TestCase)
    config.before(:suite) do
      DeferredGarbageCollection.start
    end
    config.before(:each) do
      Resolv.stub!(:getaddress=>'1.1.1.1')
      RightAws::SdbInterface.stub!(:new => FakeSdb.new)
      SimpledbResource.reset_connection
      AWS::S3.stub!(:new => FakeS3.new)
      Sqs.stub(:send_message)
      Memcached.stub(:new=>FakeMemcached.new)
    end
    config.after(:suite) do
      DeferredGarbageCollection.stop
    end
  end
end

Spork.each_run do
  UserRole.find_or_create_by_name('admin', :employee => true)
  UserRole.find_or_create_by_name('account_mgr', :employee => true)
end
