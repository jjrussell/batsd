require 'spec_helper'

describe SimpledbResource do

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

  describe "A SimpledbResource object" do
    before do
      load_model
    end

    after do
      @model.delete_all
    end

    it "should use default value correctly" do
      @model.get('foo', :default_value => 'default_value').should == 'default_value'
      @model.foo_10.should == 10
    end

    it "should write long attributes to multiple columns" do
      long_value = ''
      4501.times do |i|
        long_value += (i % 7).to_s
      end
      @model.put('long_string', long_value)
      @model.save!

      @model.get('long_string').should == long_value

      load_model
      @model.get('long_string').should == long_value

      load_model(:load_from_memcache => false, :consistent => true)
      @model.get('long_string').should == long_value
    end

    it "should handle newlines in attributes" do
      newline_value = "Ths is a \n multiline \n value"
      @model.put('newline_string', newline_value)
      @model.get('newline_string').should == newline_value
      @model.save!

      load_model
      @model.get('newline_string').should == newline_value

      load_model(:load_from_memcache => false, :consistent => true)
      @model.get('newline_string').should == newline_value
    end

    it "should cgi escape attributes when asked to" do
      cgi_escape_val = "Special chars\n\t\xc2\xa0"
      @model.put('escaped', cgi_escape_val, {:cgi_escape => true})
      @model.save!

      load_model
      @model.get('escaped').should == cgi_escape_val

      load_model(:load_from_memcache => false, :consistent => true)
      @model.get('escaped').should == cgi_escape_val
    end

    it "should handle concurrent saves" do
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
      @model.attributes.should deep_match attrs

      load_model(:load_from_memcache => false, :consistent => true)
      @model.attributes.delete('updated-at')
      @model.attributes.should deep_match attrs
    end

    it "should handle concurrent deletes" do
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
      @model.attributes.should deep_match attrs

      load_model(:load_from_memcache => false, :consistent => true)
      @model.attributes.delete('updated-at')
      @model.attributes.should deep_match attrs
    end

    it "should handle adding and replacing attrs in one save operation" do
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
      @model.attributes.should deep_match attrs

      load_model(:load_from_memcache => false, :consistent => true)
      @model.attributes.delete('updated-at')
      @model.attributes.should deep_match attrs
    end

    it "should convert types" do
      @model.put('string_key', 'string_value', :type => :string)
      @model.put('int_key', 16, :type => :int)
      @model.put('float_key', 16.1616, :type => :float)
      @model.put('time_key', Time.at(16), :type => :time)
      @model.put('bool_key', false, :type => :bool)
      @model.save!

      @model.get('string_key', :type => :string).should == 'string_value'
      @model.get('int_key', :type => :int).should == 16
      @model.get('float_key', :type => :float).should == 16.1616
      @model.get('time_key', :type => :time).should == Time.at(16)
      @model.get('bool_key', :type => :bool).should be_false

      load_model(:load_from_memcache => false, :consistent => true)
      @model.get('string_key', :type => :string).should == 'string_value'
      @model.get('int_key', :type => :int).should == 16
      @model.get('float_key', :type => :float).should == 16.1616
      @model.get('time_key', :type => :time).should == Time.at(16)
      @model.get('bool_key', :type => :bool).should be_false
    end

    it "should use sdb attrs" do
      @model.foo = 'bar'
      @model.foo_time = Time.at(16)
      @model.foo_10.should == 10
      @model.foo_10 = 10
      @model.foo_array = 'a'
      @model.foo_array.should == ['a']
      @model.foo_array = 'b'
      @model.foo_bool = true
      @model.save!

      @model.foo_10.should == 10
      @model.foo.should == 'bar'
      @model.foo_time.should == Time.at(16)
      SortedSet.new(@model.foo_array).should == SortedSet.new(['a', 'b'])
      @model.foo_bool.should == true

      load_model(:load_from_memcache => false, :consistent => true)
      @model.foo_10.should == 10
      @model.foo.should == 'bar'
      @model.foo_time.should == Time.at(16)
      SortedSet.new(@model.foo_array).should == SortedSet.new(['a', 'b'])
      @model.foo_bool.should be_true
      @model.updated_at.should > Time.now - 1.minutes
    end

    it "should handle expected attributes" do
      @model.put('version', 1)
      begin
        @model.save!(:expected_attr => {'version' => 1})
        fail("Should have raised ExpectedAttributeError")
      rescue Simpledb::ExpectedAttributeError
      end

      @model.save!(:expected_attr => {'version' => nil})

      load_model(:load_from_memcache => false, :consistent => true)
      @model.get('version').should == '1'

      Testing.transaction(:key => @model.key, :consistent => true) do |m|
        m.foo = "bar"
      end

      load_model(:load_from_memcache => false, :consistent => true)
      @model.get('version').should == '2'
      @model.foo.should == 'bar'
    end

    it "should handle concurrent transactions" do
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

      m.foo_10.should == 13
    end
  end

  describe "Many Simpledb rows" do
    before do
      @rows = []
      10.times do |i|
        m = Testing.new(:key => "select-#{i}")
        m.put('selectable_value', i)
        m.save!
        @rows << m
      end
    end

    after do
      @rows.each do |m|
        m.delete_all
      end
    end

    it "should be counted correctly and selectable" do
      Testing.count(:where =>"itemName() like 'select-%'", :consistent => true).should == 10

      m = Testing.select(:where => "selectable_value = '3'", :consistent => true)[:items][0]
      m.key.should == 'select-3'

      m = SimpledbResource.select(:where => "selectable_value = '3'", :domain_name => 'testing', :consistent => true)[:items][0]
      m.key.should == 'select-3'

      response = Testing.select(:where =>"selectable_value >= '0'", :limit => 2, :order_by => "selectable_value", :consistent => true)
      response[:items].length.should == 2

      val = 2
      Testing.select(:where =>"selectable_value >= '0'", :limit => 2, :order_by => "selectable_value",
          :next_token => response[:next_token], :consistent => true) do |m|
        m.get('selectable_value').should == val.to_s
        val += 1
      end

      count = 0
      Testing.count_async(:where =>"itemName() like 'select-%'", :consistent => true) do |c|
        count = c
      end.run
      count.should == 10
    end
  end
end
