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

def fix_count_for_sharded_sdb_models
  class << SimpledbShardedResource
    def count_with_spec_fix(opts = {})
      if opts[:domain_name].present?
        count_without_spec_fix(opts)
      else
        all_domain_names.inject(0) do |sum, domain_name|
          sum += count_without_spec_fix(opts.merge(:domain_name => domain_name))
        end
      end
    end
    alias_method_chain :count, :spec_fix
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
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.include(SpecHelpers)
    config.include(DashboardHelpers)
    config.include(Authlogic::TestCase)
    config.before(:suite) do
      DeferredGarbageCollection.start
    end
    config.before(:each) do
      AnalyticsLogger::AMQPClient.stub(:publish)
      Resolv.stub!(:getaddress=>'1.1.1.1')
      RightAws::SdbInterface.stub!(:new => FakeSdb.new)
      SimpledbResource.reset_connection
      AWS::S3.stub!(:new => FakeS3.new)
      Sqs.stub(:send_message)
      Memcached.stub(:new) {|*args| FakeMemcached.new(*args)}
      Mc.reset_connection
      Mc.flush('totally_serious')
    end
    config.after(:suite) do
      DeferredGarbageCollection.stop
    end
  end

  fix_count_for_sharded_sdb_models
end

Spork.each_run do
  UserRole.find_or_create_by_name('admin', :employee => true)
  UserRole.find_or_create_by_name('account_mgr', :employee => true)
end
