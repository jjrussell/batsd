require 'test_helper'

class CounterTest < ActiveSupport::TestCase
  
  Counter::const_set('MAX_ATTRS', 20)
  
  ##
  # A Mock SimpledbResource, with Counter included. 
  # Makes all private methods public.
  # Also includes a simple in-memory sdb interface, such that calling save and load
  # will work correctly.
  class MockCounter < Counter
    
    def self.reset_in_mem_sdb
      @@in_mem_sdb = {}
    end
    self.reset_in_mem_sdb
    
    def initialize(domain_name, key, options = {})
      super
      
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
    
    def get_next_row
      unless @next_row
        @next_row = MockCounter.new(@domain_name, get_next_row_name)
      end
      return @next_row
    end
    
    def load(load_from_memcache)
      @attributes = {}
      if @@in_mem_sdb[@domain_name] and @@in_mem_sdb[@domain_name][@key]
        @attributes = @@in_mem_sdb[@domain_name][@key]
      end
    end
    
    def save(options = {})
      unless @@in_mem_sdb[@domain_name]
        @@in_mem_sdb[@domain_name] = {}
      end
      @@in_mem_sdb[@domain_name][@key] = @attributes
    end
    
  end
  
  ##
  # A real counter, which interfaces with real simpledb.
  # All private methods are made punlic.
  class RealCounter < Counter
    def initialize(key)
      super 'testing', key
      
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
  end
  
  def setup
    MockCounter.reset_in_mem_sdb
    @model = MockCounter.new('a_domain', 'a_key')
  end
  
  def test_create_value
    @model.parse_value(@model.create_value(1))
    assert_not_equal @model.create_value(1), @model.create_value(1), 
        'create_value should return a different key number with every call.'
  end
  
  def test_parse_value
    count, time = @model.parse_value("15.1255842231.3094.111")
    assert_equal 15, count
    assert_equal Time.at(1255842231.3094), time
  end
  
  def test_get_count_simple
    @model.put('a', @model.create_value(1), {:replace => false})
    @model.put('a', @model.create_value(2), {:replace => false})
    @model.put('a', @model.create_value(3), {:replace => false})
    @model.put('a', @model.create_value(4), {:replace => false})
    @model.put('a', @model.create_value(5), {:replace => false})
  
    assert_equal 5, @model.get_count('a')
  end
  
  def test_get_count_with_increment
    assert_equal 0, @model.get_count('a')
    @model.increment_count('a')
    assert_equal 1, @model.get_count('a')
    @model.increment_count('a')
    assert_equal 2, @model.get_count('a')
    
    @model.put('a', @model.create_value(2), {:replace => false})
    assert_equal 3, @model.get_count('a')
    
    @model.increment_count('a')
    assert_equal 4, @model.get_count('a')
    
    @model.put('a', @model.create_value(1), {:replace => false})
    assert_equal 5, @model.get_count('a')
  end
  
  def test_get_count_hash_simple
    @model.put('a', @model.create_value(1), {:replace => false})
    @model.put('a', @model.create_value(2), {:replace => false})
    @model.put('a', @model.create_value(2), {:replace => false})
    @model.put('a', @model.create_value(3), {:replace => false})
    @model.put('a', @model.create_value(4), {:replace => false})
    
    assert_equal([{1 => 1, 2 => 2, 3 => 1, 4 => 1}, 1, 4], @model.get_count_hash('a'))
  end
  
  def test_get_count_hash_with_blacklist
    @model.put('a', @model.create_value(1), {:replace => false})
    @model.put('a', @model.create_value(1), {:replace => false})
    @model.put('a', @model.create_value(2), {:replace => false})
    @model.put('a', @model.create_value(2), {:replace => false})
    @model.put('a', @model.create_value(3), {:replace => false})
    
    count_hash = @model.get_count_hash('a', Set.new([1]))[0]
    assert_equal({2 => 2, 3 => 1}, count_hash)
  end
  
  def test_get_blacklist
    @model.put('a', @model.create_value(8), {:replace => false})
    def @model.get_time
      "%.6f" %  (Time.now.utc.to_f - 100)
    end
    @model.put('a', @model.create_value(1), {:replace => false})
    assert_equal Set.new([8]), @model.get_blacklist('a')
  end
  
  def test_delete_uneeded
    @model.put('a', @model.create_value(6), {:replace => false})
    def @model.get_time
      "%.6f" %  (Time.now.utc.to_f - 100)
    end
    @model.put('a', @model.create_value(1), {:replace => false})
    @model.put('a', @model.create_value(2), {:replace => false})
    @model.put('a', @model.create_value(3), {:replace => false})
    @model.put('a', @model.create_value(4), {:replace => false})
    @model.put('a', @model.create_value(4), {:replace => false})
    @model.put('a', @model.create_value(5), {:replace => false})
    
    @model.delete_uneeded('a')
    
    assert_equal( { 4 => 2, 5 => 1, 6 => 1 }, @model.get_count_hash('a')[0])
  end
  
  def test_get_num_attrs
    @model.put('a', '1')
    @model.put('a', '2', {:replace => false})
    @model.put('a', '3', {:replace => false})
    @model.put('b', '1')
    @model.put('c', '1')
    @model.put('c', '2', {:replace => false})
    
    assert_equal(6, @model.get_num_attrs)
  end
  
  def test_get_next_row_name
    assert('a_key-count1', @model.get_next_row_name)
    
    @model.key = 'a_key-count1'
    assert_equal('a_key-count2', @model.get_next_row_name)
    
    @model.key = 'a_key-count10'
    assert_equal('a_key-count11', @model.get_next_row_name)
  end
  
  ##
  # Tests the mock counter's save and load methods.
  def test_save_and_load
    @model.put('a', 'a1')
    @model.put('a', 'a2', {:replace => false})
    @model.put('b', 'b')
    @model.save
    
    model2 = MockCounter.new(@model.domain_name, @model.key)
    assert_equal(@model.attributes, model2.attributes)
  end
  
  def test_increment_multi_row
    30.times do
      @model.increment_count('a')
    end
    assert_equal('1', @model.get('DISTRIBUTED_COUNT'))
    assert_equal(30, @model.get_count('a'))
  end
  
  ##
  # This tests the counter against live simpledb. For this reason, it is a much slower test,
  # but it is necessary to catch real problems.
  def test_real
    key_name = "key-#{rand(999999)}"
    30.times do
      counter = RealCounter.new(key_name)
      counter.increment_count('a')
      counter.save
    end
    
    # Unfortunately, in order to guarantee consistency, we need to sleep.
    sleep(5)
    
    counter = RealCounter.new(key_name)
    assert_equal 30, counter.get_count('a', {:use_memcache => true})
    assert_equal 30, counter.get_count('a', {:use_memcache => false})
    assert_equal '1', counter.get('DISTRIBUTED_COUNT')
    
    main_row_count = counter.get_count('a', {:use_memcache => false, :this_row_only => true})
    
    distributed_row = RealCounter.new(counter.get_next_row_name)
    assert_nil(distributed_row.get('DISTRIBUTED_COUNT'))
    assert_equal 30 - main_row_count, distributed_row.get_count('a', {:use_memcache => false})
    
    counter.delete_all
    sleep(5)
    counter = RealCounter.new(key_name)
    distributed_row = RealCounter.new(counter.get_next_row_name)
    
    assert counter.attributes.empty?
    assert distributed_row.attributes.empty?
  end
end