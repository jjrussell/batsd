require 'test_helper'

class CounterTest < ActiveSupport::TestCase
  
  class Model
    include Counter
    include Amazon::SDB
    attr_accessor :attributes
    def initialize
      @attributes = Multimap.new
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
    
    def get(attr_name)
      @attributes.get(attr_name, {:force_array => true})
    end
    
    def put(attr_name, value)
      attributes.put(attr_name, value, {:replace => false})
    end
    
    def put_all(attr_name, values)
      attributes.put(attr_name, values, {:replace => true})
    end
  end
  
  def setup
    @model = Model.new
  end
  
  def test_get_time_and_pid
    assert_not_equal @model.get_time_and_pid, @model.get_time_and_pid, 
        'get_time_and_pid should return a unique number with every call.'
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
    @model.put('a', @model.create_value(1))
    @model.put('a', @model.create_value(2))
    @model.put('a', @model.create_value(3))
    @model.put('a', @model.create_value(4))
    @model.put('a', @model.create_value(5))

    assert_equal 5, @model.get_count('a')
  end
  
  def test_get_count_with_increment
    assert_equal 0, @model.get_count('a')
    @model.increment_count('a')
    assert_equal 1, @model.get_count('a')
    @model.increment_count('a')
    assert_equal 2, @model.get_count('a')
    
    @model.put('a', @model.create_value(2))
    assert_equal 3, @model.get_count('a')
    
    @model.increment_count('a')
    assert_equal 4, @model.get_count('a')
    
    @model.put('a', @model.create_value(1))
    puts @model.attributes.to_h.to_json
    assert_equal 5, @model.get_count('a')
  end
  
  def test_get_count_hash_simple
    @model.put('a', @model.create_value(1))
    @model.put('a', @model.create_value(2))
    @model.put('a', @model.create_value(2))
    @model.put('a', @model.create_value(3))
    @model.put('a', @model.create_value(4))
    
    assert_equal([{1 => 1, 2 => 2, 3 => 1, 4 => 1}, 1, 4], @model.get_count_hash('a'))
  end
  
  def test_get_count_hash_with_blacklist
    @model.put('a', @model.create_value(1))
    @model.put('a', @model.create_value(1))
    @model.put('a', @model.create_value(2))
    
    count_hash = @model.get_count_hash('a', Set.new([1]))[0]
    assert_equal({2 => 1}, count_hash)
  end
  
  def test_get_blacklist
    @model.put('a', @model.create_value(8))
    def @model.get_time_and_pid
      "%.6f.%i" %  [Time.now.utc.to_f - 100, Process.pid]
    end
    @model.put('a', @model.create_value(1))
    assert_equal Set.new([8]), @model.get_blacklist('a')
  end
  
  def test_delete_uneeded
    @model.attributes['a'] = @model.create_value(6)
    def @model.get_time_and_pid
      "%.6f.%i" %  [Time.now.utc.to_f - 100, Process.pid]
    end
    @model.put('a', @model.create_value(1))
    @model.put('a', @model.create_value(2))
    @model.put('a', @model.create_value(3))
    @model.put('a', @model.create_value(4))
    @model.put('a', @model.create_value(5))
    
    @model.delete_uneeded('a')
    
    assert_equal( { 5 => 1, 6 => 1 }, @model.get_count_hash('a')[0])
  end
end