require 'test_helper'

class CounterTest < ActiveSupport::TestCase
  
  class Model
    include Counter
    attr_accessor :attributes
    def initialize
      @attributes = {}
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
  end
  
  def setup
    @model = Model.new
    
  end
  
  def test_get_time_and_pid
    assert_not_equal @model.get_time_and_pid, @model.get_time_and_pid, 
        'get_time_and_pid should return a unique number with every call.'
  end
  
  def test_create_key
    @model.parse_key(@model.create_key('a'))
    assert_not_equal @model.create_key('a'), @model.create_key('a'), 
        'create_key should return a different key number with every call.'
  end
  
  def test_parse_key
    time = @model.parse_key("attr.salt.1255842231.3094.111")
    assert_equal Time.at(1255842231.3094), time
  end
  
  def test_get_count_simple
    @model.attributes[@model.create_key('a')] = 1
    @model.attributes[@model.create_key('a')] = 2
    @model.attributes[@model.create_key('a')] = 2
    @model.attributes[@model.create_key('a')] = 3
    @model.attributes[@model.create_key('a')] = 5
    assert_equal 5, @model.get_count('a')
  end
  
  def test_get_count_with_increment
    assert_equal 0, @model.get_count('a')
    @model.increment_count('a')
    assert_equal 1, @model.get_count('a')
    @model.increment_count('a')
    assert_equal 2, @model.get_count('a')
    
    @model.attributes[@model.create_key('a')] = 2
    assert_equal 3, @model.get_count('a')
    
    @model.increment_count('a')
    assert_equal 4, @model.get_count('a')
    
    @model.attributes[@model.create_key('a')] = 1
    assert_equal 5, @model.get_count('a')
  end
  
  def test_get_count_hash_simple
    @model.attributes[@model.create_key('a')] = 1
    @model.attributes[@model.create_key('a')] = 2
    @model.attributes[@model.create_key('a')] = 2
    @model.attributes[@model.create_key('a')] = 3
    @model.attributes[@model.create_key('a')] = 4
    
    assert_equal([{1 => 1, 2 => 2, 3 => 1, 4 => 1}, 1, 4], @model.get_count_hash('a'))
  end
  
  def test_get_count_hash_with_blacklist
    @model.attributes[@model.create_key('a')] = 1
    @model.attributes[@model.create_key('a')] = 1
    @model.attributes[@model.create_key('a')] = 2
    
    hash = @model.get_count_hash('a', Set.new([1]))
    assert_equal({2 => 1}, hash[0])
  end
  
  def test_get_blacklist
    @model.attributes[@model.create_key('a')] = 8
    def @model.get_time_and_pid
      "%.6f.%i" %  [Time.now.to_f - 100, Process.pid]
    end
    @model.attributes[@model.create_key('a')] = 1
    assert_equal Set.new([8]), @model.get_blacklist('a')
  end
  
  def test_delete_uneeded
    @model.attributes[@model.create_key('a')] = 6
    def @model.get_time_and_pid
      "%.6f.%i" %  [Time.now.to_f - 100, Process.pid]
    end
    @model.attributes[@model.create_key('a')] = 1
    @model.attributes[@model.create_key('a')] = 1
    @model.attributes[@model.create_key('a')] = 2
    @model.attributes[@model.create_key('a')] = 2
    @model.attributes[@model.create_key('a')] = 5
    
    @model.delete_uneeded('a')
    
    assert_equal( { 5 => 1, 6 => 1 }, @model.get_count_hash('a')[0])
  end
end