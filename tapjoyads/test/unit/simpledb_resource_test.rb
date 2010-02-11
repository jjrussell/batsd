require 'test_helper'

class SimpledbResourceTest < ActiveSupport::TestCase
  ##
  # A real model, which interfaces with real simpledb.
  # All private methods are made punlic.
  class Testing < SimpledbResource
    self.domain_name = 'testing'
    
    self.sdb_attr :foo
    self.sdb_attr :foo_10, {:type => :int, :default_value => 10}
    self.sdb_attr :foo_time, {:type => :time}
    self.sdb_attr :foo_array, {:cgi_escape => true, :replace => false, :force_array => true}
    
    def initialize(options = {})
      super
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
  end
  
  class Testing2 < SimpledbResource
    self.domain_name = 'testing'
    
    self.sdb_attr :foo2
    
    def initialize(options = {})
      super
      saved_private_methods = self.private_methods
      self.class_eval { public *saved_private_methods }
    end
  end
  
  ##
  # All "long" tests are merged into a single test case. This is because in order to guarantee 
  # consistency, we must sleep between writes. Therefore this is set up to have all writes
  # occur in write* methods, and all reads occur in read* methods. This test simply calls 
  # the write and read methods, with a single sleep in between.
  test "long tests" do
    write_long_attributes
    write_newlines_in_attributes
    write_cgi_escape
    write_concurrent_saves
    write_concurrent_deletes
    write_select_and_count
    write_type_conversion
    write_sdb_attr
    
    sleep(10)
    
    read_long_attributes
    read_newlines_in_attributes
    read_cgi_escape
    read_concurrent_saves
    read_concurrent_deletes
    read_select_and_count
    read_type_converstion
    read_sdb_attr
  end
  
  test "default value" do
    m = Testing.new
    assert_equal('default_value', m.get('foo', :default_value => 'default_value'))
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
    @expected_attrs_concurrent_deletes.each do |key, value|
      assert_equal(SortedSet.new(value), SortedSet.new(m.attributes[key]))
    end
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
  
  def write_type_conversion
    m = Testing.new(:key => 'type_conversion')
    m.put('string_key', 'string_value', :type => :string)
    m.put('int_key', 16, :type => :int)
    m.put('float_key', 16.1616, :type => :float)
    m.put('time_key', Time.at(16), :type => :time)
    m.save

    assert_equal('string_value', m.get('string_key', :type => :string))
    assert_equal(16, m.get('int_key', :type => :int))
    assert_equal(16.1616, m.get('float_key', :type => :float))
    assert_equal(Time.at(16), m.get('time_key', :type => :time))
  end
  def read_type_converstion
    m = Testing.new(:key => 'type_conversion')
    
    assert_equal('string_value', m.get('string_key', :type => :string))
    assert_equal(16, m.get('int_key', :type => :int))
    assert_equal(16.1616, m.get('float_key', :type => :float))
    assert_equal(Time.at(16), m.get('time_key', :type => :time))
    m.delete_all
  end
  
  def write_sdb_attr
    m = Testing.new(:key => 'sdb_attr')
    m.foo = 'bar'
    m.foo_time = Time.at(16)
    assert_equal(10, m.foo_10)
    m.foo_10 = 10
    m.foo_array = 'a'
    m.foo_array = 'b'
    m.save
    
    assert_equal(10, m.foo_10)
    assert_equal('bar', m.foo)
    assert_equal(Time.at(16), m.foo_time)
    assert_equal(SortedSet.new(['a', 'b']), SortedSet.new(m.foo_array))
    
    m2 = Testing2.new(:key => 'sdb_attr2')
    m2.foo2 = 'foo2'
    m2.save
  end
  def read_sdb_attr
    m = Testing.new(:key => 'sdb_attr')
    assert_equal(10, m.foo_10)
    assert_equal('bar', m.foo)
    assert_equal(Time.at(16), m.foo_time)
    assert_equal(SortedSet.new(['a', 'b']), SortedSet.new(m.foo_array))
    
    m2 = Testing2.new(:key => 'sdb_attr2')
    assert_equal('foo2', m2.foo2)
    
    m.delete_all
    m2.delete_all
  end
end