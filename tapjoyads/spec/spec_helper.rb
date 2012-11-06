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
  require 'db/seeds'
  require 'factory_girl'
  require 'authlogic/test_case'
  require 'hpricot'
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  VCR.configure do |c|
    c.cassette_library_dir     = 'spec/cassettes'
    c.hook_into                  :fakeweb
    c.default_cassette_options = { :record => :new_episodes }
    c.allow_http_connections_when_no_cassette = true
    c.ignore_localhost = true
  end

  RSpec.configure do |config|
    config.extend VCR::RSpec::Macros

    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
    config.include(SpecHelpers)
    config.include(DashboardHelpers)
    config.include(Authlogic::TestCase)

    config.before(:suite) do
      DeferredGarbageCollection.start
      SimpledbResource.create_domain(RUN_MODE_PREFIX + "testing")

      class Timecop
        def self.at_time(time)
          Timecop.freeze(time)
            yield
        ensure
          Timecop.return
        end
      end
    end

    config.before(:each) do
      AnalyticsLogger.stub(:publish => true)
      Resolv.stub!(:getaddress=>'1.1.1.1')
      $fake_sdb = FakeSdb.new
      RightAws::SdbInterface.stub!(:new => $fake_sdb)
      SimpledbResource.reset_connection
      AWS::S3.stub!(:new => FakeS3.new)
      Sqs.stub(:send_message)
      Memcached.stub(:new) {|*args| FakeMemcached.new(*args)}
      Mc.reset_connection
      Mc.flush('totally_serious')
      OfferCacher.stub(:get_offer_stats) { Hash.new(0) }
      I18n.locale = :en
      Device.stub(:cached_count) { Device.count }
    end

    config.after(:each) do
      ActiveRecordDisabler.enable_queries!
    end

    config.after(:suite) do
      SimpledbResource.reset_connection
      SimpledbResource.delete_domain(RUN_MODE_PREFIX + "testing")
      DeferredGarbageCollection.stop
    end
  end

  fix_count_for_sharded_sdb_models
end

Spork.each_run do
end
