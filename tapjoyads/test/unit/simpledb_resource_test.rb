require 'test_helper'

class SimpledbResourceTest < ActiveSupport::TestCase
  ##
  # A real model, which interfaces with real simpledb.
  # All private methods are made punlic.
  class Testing < SimpledbResource
    self.domain_name = 'testing'
    
    def initialize(options = {})
      super
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
  end
  
  ##
  # All tests are merged into a single test case. This is because in order to guarantee 
  # consistency, we must sleep between writes. Therefore this is set up to have all writes
  # occur in write* methods, and all reads occur in read* methods. This test simply calls 
  # the write and read methods, with a single sleep in between.
  test "all tests" do
    write_long_attributes
    write_newlines_in_attributes
    write_cgi_escape
    write_concurrent_saves
    write_concurrent_deletes
    write_select_and_count
    
    sleep(10)
    
    read_long_attributes
    read_newlines_in_attributes
    read_cgi_escape
    read_concurrent_saves
    read_concurrent_deletes
    read_select_and_count
  end
  
  def write_long_attributes
    m = Testing.new(:key => 'long_attrs')
    @long_value = ''
    4501.times do |i|
      @long_value += (i % 7).to_s
    end
    m.put('long_string', @long_value)
    m.save
    
    assert_equal(@long_value, m.get('long_string'))
  end
  def read_long_attributes
    m = Testing.new(:key => 'long_attrs')
    assert_equal(@long_value, m.get('long_string'))
    
    m = Testing.new(:key => 'long_attrs', :load_from_memcache => false)
    assert_equal(@long_value, m.get('long_string'))
    m.delete_all
  end
  
  def write_newlines_in_attributes
    m = Testing.new(:key => 'newlines_in_attributes')
    @newline_value = "Ths is a \n multiline \n value"
    m.put('newline_string', @newline_value)
    assert_equal(@newline_value, m.get('newline_string'))
    m.serial_save
    m = Testing.new(:key => 'newlines_in_attributes')
    assert_equal(@newline_value, m.get('newline_string'))
  end
  def read_newlines_in_attributes
    m = Testing.new(:key => 'newlines_in_attributes', :load_from_memcache => false)
    assert_equal(@newline_value, m.get('newline_string'))
    m.delete_all
  end
  
  def write_cgi_escape
    m = Testing.new(:key => 'cgi_escape')
    @cgi_escape_val = "Special chars\n\t\xc2\xa0"
    m.put('escaped', @cgi_escape_val, {:cgi_escape => true})
    m.save
  end
  def read_cgi_escape
    m = Testing.new(:key => 'cgi_escape')
    assert_equal(@cgi_escape_val, m.get('escaped'))
    
    m = Testing.new(:key => 'cgi_escape', :load_from_memcache => false)
    assert_equal(@cgi_escape_val, m.get('escaped'))
    m.delete_all
  end
  
  def write_concurrent_saves
    @expected_attrs_concurrent_saves = {}
    
    thread_list = []
    10.times do |i|
      m = Testing.new(:key => 'concurrent_saves')
      m.put("#{i}", 'value')
      m.put("#{i}", 'value2', {:replace => false})
      thread_list.push(m.save({:updated_at => false}))
      @expected_attrs_concurrent_saves["#{i}"] = ['value', 'value2']
    end
    
    thread_list.each do |thread|
      thread.join
    end
    
    m = Testing.new({:key => 'concurrent_saves', :load => false})
    m.put("9", 'value3', {:replace => false})
    m.save(:updated_at => false).join
    @expected_attrs_concurrent_saves['9'].push('value3')
    
    m = Testing.new(:key => 'concurrent_saves')
    assert_equal(@expected_attrs_concurrent_saves, m.attributes)
  end
  def read_concurrent_saves
    m = Testing.new({:key => 'concurrent_saves', :load_from_memcache => false})
    assert_equal(@expected_attrs_concurrent_saves, m.attributes)
    m.delete_all
  end
  
  def write_concurrent_deletes
    @expected_attrs_concurrent_deletes = {}
    
    m = Testing.new(:key => 'concurrent_deletes')
    10.times do |i|
      m.put("#{i}", 'value')
      m.put("#{i}", 'value2', {:replace => false})
      @expected_attrs_concurrent_deletes["#{i}"] = ['value', 'value2']
    end
    
    m.serial_save(:updated_at => false)
    # Short sleep before deleting. Not sure if this is necessary.
    sleep(2)
    
    thread_list = []
    3.times do |i|
      m = Testing.new(:key => 'concurrent_deletes')
      m.delete("#{i}", "value2")
      thread_list.push(m.save({:updated_at => false}))
      @expected_attrs_concurrent_deletes["#{i}"] = ['value']
    end
    
    thread_list.each do |thread|
      thread.join
    end
    
    m = Testing.new(:key => 'concurrent_deletes')
    assert_equal(@expected_attrs_concurrent_deletes, m.attributes)
  end
  def read_concurrent_deletes
    m = Testing.new({:key => 'concurrent_deletes', :load_from_memcache => false})
    assert_equal(@expected_attrs_concurrent_deletes, m.attributes)
    m.delete_all
  end
  
  def write_select_and_count
    10.times do |i|
      m = Testing.new(:key => "select-#{i}")
      m.put('selectable_value', i)
      m.save
    end
  end
  def read_select_and_count
    assert_equal(10, Testing.count(:where =>"itemName() like 'select-%'"))
    
    m = Testing.select(:where => "selectable_value = '3'")[:items][0]
    assert_equal('select-3', m.key)
    
    m = SimpledbResource.select(:where => "selectable_value = '3'", :domain_name => 'testing')[:items][0]
    assert_equal('select-3', m.key)
    
    response = Testing.select(:where =>"selectable_value >= '0'", :limit => 2, :order_by => "selectable_value")
    assert_equal(2, response[:items].length)
    
    val = 2
    Testing.select(:where =>"selectable_value >= '0'", :limit => 2, :order_by => "selectable_value", 
        :next_token => response[:next_token]) do |m|
      assert_equal(val.to_s, m.get('selectable_value'))  
      val += 1
    end
    
    10.times do |i|
      m = Testing.new(:key => "select-#{i}")
      m.delete_all
    end
  end
end