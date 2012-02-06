require 'spec_helper'

describe Mc do
  it "gets and saves" do
    Mc.put('key', 'value')
    Mc.get('key').should == 'value'

    val = Mc.get('non-key') do
      'bar'
    end

    val.should == 'bar'

    val = Mc.get_and_put('foo2') do
      'bar2'
    end

    val.should == 'bar2'

    val = Mc.get_and_put('foo2') do
      'not accessed'
    end
    val.should == 'bar2'
  end

  it "gets and saves multi-threaded" do
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
      Mc.get("thread-#{i}", true).should == "#{i}"
    end
  end

  it "increments count" do
    key = 'foocount'
    key2 = 'foocount2'
    Mc.get_count(key).should == 0

    Mc.increment_count(key).should == 1

    5.times do
      Mc.increment_count(key)
    end

    Mc.get_count(key).should == 6

    Mc.increment_count(key, false, 1.week, 10)
    Mc.get_count(key).should == 16

    Mc.get_count(key2).should == 0
    Mc.increment_count(key2, false, 1.week, -5).should == -5
    Mc.get_count(key2).should == -5
    Mc.increment_count(key2, false, 1.week, -1).should == -6
    Mc.increment_count(key2, false, 1.week, 2).should == -4
    Mc.increment_count(key2, false, 1.week, 7).should == 3
  end

  it "compares and swaps" do

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

    Mc.get('foo').should == expected_val
  end
end
