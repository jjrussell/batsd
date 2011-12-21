require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
  require 'spec/autorun'
  require 'spec/rails'
  require "authlogic/test_case"

  Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

  Spec::Runner.configure do |config|
    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false
    config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
    config.mock_with :mocha
  end

  def login_as(user)
    UserSession.create(user)
  end

  def should_respond_with_json_error(code)
    should respond_with(code)
    should respond_with_content_type(:json)
    result = JSON.parse(response.body)
    result['success'].should be_false
    result['error'].should be_present
  end

  def should_respond_with_json_success(code)
    should respond_with(200)
    should respond_with_content_type(:json)
    result = JSON.parse(response.body)
    result['success'].should be_true
    result['error'].should_not be_present
  end

  def stub_offers
    mock_bucket = mock()
    mock_image = mock()
    mock_image.stubs(:read).returns('fake image')
    mock_hash = { 'icons/checkbox.jpg' => mock_image }
    mock_bucket.stubs(:objects).returns(mock_hash)
    S3.stubs(:bucket).returns(mock_bucket)
    Offer.any_instance.stubs(:save_icon!)
    Offer.any_instance.stubs(:sync_banner_creatives!)
  end
end

Spork.each_run do
end

