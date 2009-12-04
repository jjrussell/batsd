require 'test_helper'

class SimpledbResourceTest < ActiveSupport::TestCase
  ##
  # A real model, which interfaces with real simpledb.
  # All private methods are made punlic.
  class Testing < SimpledbResource
    def initialize(key, options = {})
      super 'testing', key, options
      
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
  end
  
  def setup
    @key = "sdb-test-key-#{rand(999999)}"
    @model = Testing.new(@key)
  end
  
  def teardown
    @model.delete_all
  end
  
  test "long attributes" do
    val = ''
    4501.times do |i|
      val += (i % 10).to_s
    end
    @model.put('long_string',val)
    @model.save
    sleep(5)
    
    m = Testing.new(@key)
    assert_equal(val, m.get('long_string'))
  end
  
  test "newlines in attributes" do
    val = "Ths is a \n multiline \n value"
    @model.put('newline_string',val)
    @model.save
    sleep(5)
    
    m = Testing.new(@key)
    assert_equal(val, m.get('newline_string'))
  end
  
  test "concurrent saves interacting with memcache" do
    expected_attrs = {}
    
    thread_list = []
    10.times do |i|
      model = Testing.new(@key)
      model.put("#{i}", 'value')
      model.put("#{i}", 'value2', false)
      thread_list.push(model.save({:updated_at => false}))
      expected_attrs["#{i}"] = ['value', 'value2']
    end
    
    thread_list.each do |thread|
      thread.join
    end
    
    model = Testing.new(@key, {:load => false})
    model.put("9", 'value3', false)
    model.save({:updated_at => false, :replace => false}).join
    expected_attrs['9'].push('value3')
    
    model = Testing.new(@key)
    assert_equal(expected_attrs, model.attributes)
    
    # Sleep for consistency
    sleep(5)
    
    model = Testing.new(@key, {:load_from_memcache => false})
    assert_equal(expected_attrs, model.attributes)
    
    # Test deletes:
    3.times do |i|
      model = Testing.new(@key)
      model.delete("#{i}", "value2")
      thread_list.push(model.save({:updated_at => false}))
      expected_attrs["#{i}"] = ['value']
    end
    
    thread_list.each do |thread|
      thread.join
    end
    
    model = Testing.new(@key)
    assert_equal(expected_attrs, model.attributes)
    
    # Deletes take longer to become consistent, so sleep longer than usual
    sleep(10)
    model = Testing.new(@key, {:load_from_memcache => false})
    assert_equal(expected_attrs, model.attributes)
    
  end
end