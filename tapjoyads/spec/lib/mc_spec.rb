require 'spec_helper'

describe Mc do
  describe '.get' do
    context 'with multiple keys' do
      context 'with first key a miss' do
        it 'returns second key val' do
          cache = Memcached.new
          cache.stub(:get).with('key1').and_raise(Memcached::NotFound)
          cache.stub(:get).with('key2').and_return('val')
          Mc.get(['key1', 'key2'], false, [cache]).should == 'val'
        end

        it 'only adds last key found' do
          missing_cache = FakeMemcached.new
          cache = FakeMemcached.new
          missing_cache.should_receive(:get).twice.and_raise(Memcached::NotFound)
          cache.should_receive(:get).with('key1').and_raise(Memcached::NotFound)
          cache.should_receive(:get).with('key2').and_return('val')
          missing_cache.should_not_receive(:add).with('key1', 'val', 1.week.to_i)
          missing_cache.should_receive(:add).with('key2', 'val', 1.week.to_i)
          Mc.get(['key1', 'key2'], false, [missing_cache, cache]).should == 'val'
        end
      end

      context 'with all keys a miss' do
        it 'returns yield' do
          cache = Memcached.new
          cache.stub(:get).with('key1').and_raise(Memcached::NotFound)
          res = Mc.get(['key1', 'key2']) do
            'yielded_val'
          end

          res.should == 'yielded_val'
        end
      end
    end
  end

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
