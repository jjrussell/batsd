require 'test_helper'

class MemcachedTest < ActiveSupport::TestCase

  test "basic get and save" do
    Mc.put('key', 'value')
    assert_equal 'value', Mc.get('key')

    val = Mc.get('non-key') do
      'bar'
    end

    assert_equal 'bar', val

    val = Mc.get_and_put('foo2') do
      'bar2'
    end

    assert_equal 'bar2', val

    val = Mc.get_and_put('foo2') do
      'not accessed'
    end
    assert_equal 'bar2', val
  end

  test "multi-threaded" do
    thread_list = []
    10.times do |i|
      thread = Thread.new do
        Mc.put("thread-#{i}", "#{i}", true)
      end
      thread_list.push(thread)
    end

    thread_list.each do |thread|
      thread.join
    end

    10.times do |i|
      assert_equal "#{i}", Mc.get("thread-#{i}", true)
    end
  end

  test "increment count" do
    key = 'foocount'
    key2 = 'foocount2'
    assert_equal 0, Mc.get_count(key)

    assert_equal 1, Mc.increment_count(key)

    5.times do
      Mc.increment_count(key)
    end

    assert_equal 6, Mc.get_count(key)

    Mc.increment_count(key, false, 1.week, 10)
    assert_equal 16, Mc.get_count(key)

    assert_equal 0, Mc.get_count(key2)
    assert_equal -5, Mc.increment_count(key2, false, 1.week, -5)
    assert_equal -5, Mc.get_count(key2)
    assert_equal -6, Mc.increment_count(key2, false, 1.week, -1)
    assert_equal -4, Mc.increment_count(key2, false, 1.week, 2)
    assert_equal 3, Mc.increment_count(key2, false, 1.week, 7)
  end

  test "compare and swap" do

    thread_list = []
    expected_val = ''
    100.times do
      expected_val += 'a'
      thread = Thread.new do
        Mc.compare_and_swap('foo', true) do |mc_val|
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

    assert_equal(expected_val, Mc.get('foo'))
  end
end
