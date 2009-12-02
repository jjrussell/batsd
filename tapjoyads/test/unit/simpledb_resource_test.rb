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
  
  test "concurrent saves interacting with memcache" do
    expected_attrs = {}
    
    thread_list = []
    10.times do |i|
      model = Testing.new(@key)
      model.put("#{i}", "#{i}")
      thread_list.push(model.save({:updated_at => false}))
      expected_attrs["#{i}"] = ["#{i}"]
    end
    
    thread_list.each do |thread|
      thread.join
    end
    
    model = Testing.new(@key)
    assert_equal(expected_attrs, model.attributes)
    
    # Sleep for consistency
    sleep(2)
    
    model = Testing.new(@key, {:load_from_memcache => false})
    assert_equal(expected_attrs, model.attributes)
  end
end