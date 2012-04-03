require 'test/unit'
require 'mocha'
require 'will_paginate'
begin
  require 'ruby-debug'
rescue LoadError
  # no debuggging
end

class Test::Unit::TestCase
  protected
  def assert_respond_to_all object, methods
    methods.each do |method|
      [method.to_s, method.to_sym].each { |m| assert_respond_to object, m }
    end
  end
  
  def collect_deprecations
    old_behavior = WillPaginate::Deprecation.behavior
    deprecations = []
    WillPaginate::Deprecation.behavior = Proc.new do |message, callstack|
      deprecations << message
    end
    result = yield
    [result, deprecations]
  ensure
    WillPaginate::Deprecation.behavior = old_behavior
  end
end

# Wrap tests that use Mocha and skip if unavailable.
def uses_mocha(test_name)
  yield
end
