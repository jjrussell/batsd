require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
  require 'spec/autorun'
  require 'spec/rails'
  require "authlogic/test_case"
  require "capybara/rails"

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  Spec::Runner.configure do |config|
    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false
    config.fixture_path = "#{Rails.root}/spec/fixtures/"
    config.mock_with :mocha
    config.include Capybara::DSL

    config.before :each do
      SimpledbResource.reset_connection
      Mc.cache.flush
    end
  end

  def login_as(user)
    UserSession.create(user)
  end

  def games_login_as(user)
    GamerSession.create(user)
  end

  def stub_device
    mock_answers = {'Where are you from?' => 'the moon'}
    mock_device = mock()
    mock_device.stubs(:survey_answers).returns(mock_answers)
    mock_device.stubs(:survey_answers=)
    mock_device.stubs(:save)
    Device.stubs(:new).returns(mock_device)
  end

  def stub_survey_result
    mock_result = mock()
    mock_result.stubs(:udid=)
    mock_result.stubs(:click_key=)
    mock_result.stubs(:geoip_data=)
    mock_result.stubs(:answers=)
    mock_result.stubs(:save)
    SurveyResult.stubs(:new).returns(mock_result)
  end

  def should_respond_with_json_error(code)
    should respond_with(code)
    should respond_with_content_type(:json)
    result = JSON.parse(response.body)
    result['success'].should be_false
    result['error'].should be_present
  end

  def should_respond_with_json_success(code)
    should respond_with(code)
    should respond_with_content_type(:json)
    result = JSON.parse(response.body)
    result['success'].should be_true
    result['error'].should_not be_present
  end

  def fake_the_web
    Resolv.stubs(:getaddress).returns('1.1.1.1')
    RightAws::SdbInterface.stubs(:new).returns(FakeSdb.new)
    SimpledbResource.reset_connection
    AWS::S3.stubs(:new).returns(FakeS3.new)
  end

  module Spec
    module Rails
      module Example
        class ControllerExampleGroup
          class << self
            # Rails uses a tag parser which is more strict than necessary.
            # Silence the warnings with this.
            def ignore_html_warning
              @verbosity = $-v

              class_eval <<-EOV
                before :each do
                  $-v = nil
                end

                after :each do
                  $-v = #{@verbosity}
                end
              EOV
            end
          end
        end
      end
    end
  end

  def match_hash_with_arrays(expected)
    MatchHashWithArrays.new(expected)
  end

  class MatchHashWithArrays
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      @actual = actual
      match_keys && match_arrays
    end

    def failure_message_for_should
      if match_keys
        "Values do not match for key '#@bad_key'."
      else
        "Keys do not match"
      end
    end

    def match_keys
      @actual.keys.sort == @expected.keys.sort
    end

    def match_arrays
      @expected.each do |key, value|
        unless value.sort == @actual[key].sort
          @bad_key = key
          return false
        end
      end
      true
    end
  end
end

Spork.each_run do
end
