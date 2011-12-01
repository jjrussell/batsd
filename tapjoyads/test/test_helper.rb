ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

ActiveRecord::Base.send(:include, AfterCommit::AfterSavepoint) # for compatibility with after_commit gem
ActiveRecord::Base.include_after_savepoint_extensions # for compatibility with after_commit gem

require 'test_help'
require "authlogic/test_case"

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  #self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  #self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  # Add more helper methods to be used by all tests here...
  def login_as(user)
    UserSession.create(user)
  end

  def games_login_as(user)
    GamerSession.create(user)
  end

  def wrap_with_controller(new_controller)
    old_controller = @controller
    @controller = new_controller.new
    yield
    @controller = old_controller
  end
  # Tests equality of attribute hashes. An attribute hash has the form:
  # { :key1 => [value1, value2], :key2 => [value3]}
  # The value arrays may be in any order.
  def assert_attributes_equal(expected, actual, message = nil)
    assert_equal(expected.keys.sort, actual.keys.sort, "Keys do not match. #{message}")
    expected.each do |key, value|
      assert_equal(SortedSet.new(value), SortedSet.new(actual[key]), "Values don't match for key '#{key}'. #{message}")
    end
  end
end
