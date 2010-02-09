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
  
  test "increment count" do
    key = 'foocount'
    key2 = 'foocount2'
    assert_equal 0, get_count_in_cache(key)
    
    assert_equal 1, increment_count_in_cache(key)
    
    5.times do
      increment_count_in_cache(key)
    end
    
    assert_equal 6, get_count_in_cache(key)
    
    increment_count_in_cache(key, false, 1.week, 10)
    assert_equal 16, get_count_in_cache(key)
    
    assert_equal 0, get_count_in_cache(key2)
    assert_equal 5, increment_count_in_cache(key2, false, 1.week, 5)
    assert_equal 5, get_count_in_cache(key2)
  end
  
  test "compare and swap" do
    
    thread_list = []
    expected_val = ''
    10.times do
      expected_val += 'a'
      thread = Thread.new do
        compare_and_swap_in_cache('foo', true) do |mc_val|
          if mc_val
            val = mc_val + 'a'
          else
            val = 'a'
          end
          val
        end
      end
      thread_list.push(thread)
    end
    
    thread_list.each do |thread|
      thread.join
    end
    
    assert_equal(expected_val, get_from_cache('foo'))
  end
  
  test "lock on key" do
    thread_list = []
    count = 0
    num_retries = 0
    
    10.times do
      thread = Thread.new do
        begin
          lock_on_key('key_to_lock_on') do
            count += 1
            sleep(0.1)
          end
        rescue KeyExists
          num_retries += 1
          sleep(0.1)
          retry
        end
      end
      thread_list.push(thread)
    end
    
    thread_list.each do |thread|
      thread.join
    end
    
    assert_equal(10, count)
    assert(num_retries > 0)
  end
end