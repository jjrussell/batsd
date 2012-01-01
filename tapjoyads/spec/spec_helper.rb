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
end

Spork.each_run do
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
