require 'test_helper'

class SimpledbResourceTest < ActiveSupport::TestCase

  # A real model, which interfaces with real simpledb.
  class Testing < SimpledbResource
    self.domain_name = 'testing'

    self.sdb_attr :foo
    self.sdb_attr :foo_10, {:type => :int, :default_value => 10}
    self.sdb_attr :foo_time, {:type => :time}
    self.sdb_attr :foo_array, {:cgi_escape => true, :replace => false, :force_array => true}
    self.sdb_attr :foo_bool, {:type => :bool}
  end

  def load_model(options = {})
    if @model
      options = {:key => @model.key}.merge(options)
    end
    @model = Testing.new(options)
  end

  context "A SimpledbResource object" do
    setup do
      load_model
    end

    teardown do
      @model.delete_all
    end

    should "use default value correctly" do
      assert_equal('default_value', @model.get('foo', :default_value => 'default_value'))
      assert_equal(10, @model.foo_10)
    end

    should "write long attributes to multiple columns" do
      long_value = ''
      4501.times do |i|
        long_value += (i % 7).to_s
      end
      @model.put('long_string', long_value)
      @model.save!

      assert_equal(long_value, @model.get('long_string'))

      load_model
      assert_equal(long_value, @model.get('long_string'))

      load_model(:load_from_memcache => false, :consistent => true)
      assert_equal(long_value, @model.get('long_string'))
    end

    should "handle newlines in attributes" do
      newline_value = "Ths is a \n multiline \n value"
      @model.put('newline_string', newline_value)
      assert_equal(newline_value, @model.get('newline_string'))
      @model.save!

      load_model
      assert_equal(newline_value, @model.get('newline_string'))

      load_model(:load_from_memcache => false, :consistent => true)
      assert_equal(newline_value, @model.get('newline_string'))
    end

    should "cgi escape attributes when asked to" do
      cgi_escape_val = "Special chars\n\t\xc2\xa0"
      @model.put('escaped', cgi_escape_val, {:cgi_escape => true})
      @model.save!

      load_model
      assert_equal(cgi_escape_val, @model.get('escaped'))

      load_model(:load_from_memcache => false, :consistent => true)
      assert_equal(cgi_escape_val, @model.get('escaped'))
    end

    should "handle concurrent saves" do
      attrs = {}

      thread_list = []
      10.times do |i|
        m = Testing.new(:key => @model.key)
        m.put("#{i}", 'value', {:replace => false})
        m.put("#{i}", 'value2', {:replace => false})
        thread_list.push(m.save)
        attrs["#{i}"] = ['value', 'value2']
      end

      thread_list.each(&:join)

      @model.put("9", 'value3', {:replace => false})
      attrs['9'].push('value3')
      @model.save!

      load_model
      @model.attributes.delete('updated-at')
      assert_attributes_equal(attrs, @model.attributes)

      load_model(:load_from_memcache => false, :consistent => true)
      @model.attributes.delete('updated-at')
      assert_attributes_equal(attrs, @model.attributes)
    end

    should "handle concurrent deletes" do
      attrs = {}

      10.times do |i|
        @model.put("#{i}", 'value', {:replace => false})
        @model.put("#{i}", 'value2', {:replace => false})
        attrs["#{i}"] = ['value', 'value2']
      end
      @model.save!

      load_model
      thread_list = []

      @model.delete('9')
      thread_list.push(@model.save)
      attrs.delete('9')
      3.times do |i|
        m = Testing.new(:key => @model.key)
        m.delete("#{i}", "value2")
        thread_list.push(m.save)
        attrs["#{i}"] = ['value']
      end
      thread_list.each(&:join)

      load_model
      @model.attributes.delete('updated-at')
      assert_attributes_equal(attrs, @model.attributes)

      load_model(:load_from_memcache => false, :consistent => true)
      @model.attributes.delete('updated-at')
      assert_attributes_equal(attrs, @model.attributes)
    end

    should "handle adding and replacing attrs in one save operation" do
      attrs = {}

      10.times do |i|
        @model.put("#{i}", 'value')
        attrs["#{i}"] = ['value']
      end

      @model.save!

      load_model

      @model.put('1', 'replaced_value')
      @model.put('2', 'value2', {:replace => false})
      attrs['1'] = ['replaced_value']
      attrs['2'].push('value2')
      @model.save!

      load_model
      @model.attributes.delete('updated-at')
      assert_attributes_equal(attrs, @model.attributes)

      load_model(:load_from_memcache => false, :consistent => true)
      @model.attributes.delete('updated-at')
      assert_attributes_equal(attrs, @model.attributes)
    end

    should "convert types" do
      @model.put('string_key', 'string_value', :type => :string)
      @model.put('int_key', 16, :type => :int)
      @model.put('float_key', 16.1616, :type => :float)
      @model.put('time_key', Time.at(16), :type => :time)
      @model.put('bool_key', false, :type => :bool)
      @model.save!

      assert_equal('string_value', @model.get('string_key', :type => :string))
      assert_equal(16, @model.get('int_key', :type => :int))
      assert_equal(16.1616, @model.get('float_key', :type => :float))
      assert_equal(Time.at(16), @model.get('time_key', :type => :time))
      assert_equal(false, @model.get('bool_key', :type => :bool))

      load_model(:load_from_memcache => false, :consistent => true)
      assert_equal('string_value', @model.get('string_key', :type => :string))
      assert_equal(16, @model.get('int_key', :type => :int))
      assert_equal(16.1616, @model.get('float_key', :type => :float))
      assert_equal(Time.at(16), @model.get('time_key', :type => :time))
      assert_equal(false, @model.get('bool_key', :type => :bool))
    end

    should "use sdb attrs" do
      @model.foo = 'bar'
      @model.foo_time = Time.at(16)
      assert_equal(10, @model.foo_10)
      @model.foo_10 = 10
      @model.foo_array = 'a'
      assert_equal(['a'], @model.foo_array)
      @model.foo_array = 'b'
      @model.foo_bool = true
      @model.save!

      assert_equal(10, @model.foo_10)
      assert_equal('bar', @model.foo)
      assert_equal(Time.at(16), @model.foo_time)
      assert_equal(SortedSet.new(['a', 'b']), SortedSet.new(@model.foo_array))
      assert_equal(true, @model.foo_bool)

      load_model(:load_from_memcache => false, :consistent => true)
      assert_equal(10, @model.foo_10)
      assert_equal('bar', @model.foo)
      assert_equal(Time.at(16), @model.foo_time)
      assert_equal(SortedSet.new(['a', 'b']), SortedSet.new(@model.foo_array))
      assert_equal(true, @model.foo_bool)
      assert(@model.updated_at > Time.now - 1.minutes)
    end

    should "handle expected attributes" do
      @model.put('version', 1)
      begin
        @model.save!(:expected_attr => {'version' => 1})
        fail("Should have raised ExpectedAttributeError")
      rescue Simpledb::ExpectedAttributeError
      end

      @model.save!(:expected_attr => {'version' => nil})

      load_model(:load_from_memcache => false, :consistent => true)
      assert_equal('1', @model.get('version'))

      Testing.transaction(:key => @model.key, :consistent => true) do |m|
        m.foo = "bar"
      end

      load_model(:load_from_memcache => false, :consistent => true)
      assert_equal('2', @model.get('version'))
      assert_equal('bar', @model.foo)
    end

    should "handle concurrent transactions" do
      thread_list = []
      3.times do
        thread_list << Thread.new do
          Testing.transaction({:key => @model.key}, {:retries => 10}) do |m|
            m.foo_10 += 1
          end
        end
      end

      thread_list.each(&:join)

      m = Testing.new(:key => @model.key, :load_from_memcache => false, :consistent => true)

      assert_equal(13, m.foo_10)
    end
  end

  context "Many Simpledb rows" do
    setup do
      @rows = []
      10.times do |i|
        m = Testing.new(:key => "select-#{i}")
        m.put('selectable_value', i)
        m.save!
        @rows << m
      end
    end

    teardown do
      @rows.each do |m|
        m.delete_all
      end
    end

    should "be counted correctly and selectable" do
      assert_equal(10, Testing.count(:where =>"itemName() like 'select-%'", :consistent => true))

      m = Testing.select(:where => "selectable_value = '3'", :consistent => true)[:items][0]
      assert_equal('select-3', m.key)

      m = SimpledbResource.select(:where => "selectable_value = '3'", :domain_name => 'testing', :consistent => true)[:items][0]
      assert_equal('select-3', m.key)

      response = Testing.select(:where =>"selectable_value >= '0'", :limit => 2, :order_by => "selectable_value", :consistent => true)
      assert_equal(2, response[:items].length)

      val = 2
      Testing.select(:where =>"selectable_value >= '0'", :limit => 2, :order_by => "selectable_value",
          :next_token => response[:next_token], :consistent => true) do |m|
        assert_equal(val.to_s, m.get('selectable_value'))
        val += 1
      end

      count = 0
      Testing.count_async(:where =>"itemName() like 'select-%'", :consistent => true) do |c|
        count = c
      end.run
      assert_equal(10, count, "Async count")
    end
  end
end
