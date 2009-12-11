require 'test_helper'

class MemcachedHelperTest < ActiveSupport::TestCase
  include MemcachedHelper
  
  test "basic get and save" do
    save_to_cache('key', 'value')
    assert_equal 'value', get_from_cache('key')
    
    val = get_from_cache('non-key') do
      'bar'
    end
    
    assert_equal 'bar', val
    
    val = get_from_cache_and_save('foo2') do
      'bar2'
    end
    
    assert_equal 'bar2', val
    
    val = get_from_cache_and_save('foo2') do
      'not accessed'
    end
    assert_equal 'bar2', val
  end
  
  test "multi-threaded" do
    thread_list = []
    10.times do |i|
      thread = Thread.new do
        save_to_cache("thread-#{i}", "#{i}", true)
      end
      thread_list.push(thread)
    end
  
    thread_list.each do |thread|
      thread.join
    end
    
    10.times do |i|
      assert_equal "#{i}", get_from_cache("thread-#{i}", true)
    end
  end
end