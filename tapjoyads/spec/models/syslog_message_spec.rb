require 'spec_helper'

describe SyslogMessage do
  describe '#define_attr' do
    let(:subclass) { Class.new(SyslogMessage) {
      define_attr :str
      define_attr :flt, :type => :float
      define_attr :int, :type => :int
      define_attr :bul, :type => :bool
      define_attr :url, :cgi_escape => true
      define_attr :ary, :replace => false, :force_array => true
    }}

    let(:instance) {
      instance = subclass.new
      def instance.__attr(key); @attributes[key]; end
      instance
    }

    it 'creates reader and writer methods for the named attribute' do
      [:str, :str=].each { |m| instance.should respond_to(m) }
    end

    it 'converts attributes to their specified types' do
      # strings
      instance.str = 'hello'
      instance.str.should == 'hello'
      instance.str = :goodbye
      instance.str.should == 'goodbye'

      # floats
      instance.flt = 1
      instance.flt.should be_a(Float)

      instance.flt = '1.3'
      instance.flt.should == 1.3

      # ints
      instance.int = '987654321'
      instance.int.should == 987654321

      instance.int = 50.5
      instance.int.should == 50

      # bools
      instance.bul = 1
      instance.bul.should == true

      instance.bul = 'this is not zero, nil, or false'
      instance.bul.should == true
    end

    it 'writes into an array if `replace` is false for an attribute' do
      [:one, :two, :three].each { |item| instance.ary = item }
      instance.ary.should == ['one', 'two', 'three']
    end

    it 'returns nil for an unset attribute unless `force_array` is true' do
      instance.ary.should == []
      instance.str.should == nil
    end
  end
end
