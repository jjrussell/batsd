require 'spec_helper'
require 'lazy_init_proxy'

describe LazyInitProxy do
  let(:target) do
    Object.new.tap do |o|
      class << o
        def foo(*args); end
      end
    end
  end

  let(:block)      { lambda { target } }
  let(:subject)    { LazyInitProxy.new(&block) }

  describe "method call" do

    context do
      # Crappy hack around the inability to mock #call and have it be seen after passing &block
      let(:block) { lambda { i ||= 0; i+=1 } }

      it "should call the block when a method is called" do
        subject.to_i.should == 1
      end
    end

    it "should delegate the method to the target" do
      target.should_receive(:foo).with(1, "a").and_return("zoop")
      subject.foo(1, "a").should == "zoop"
    end

    context "after being called" do
      let(:block) { lambda { i ||= 0; i+=1 } }

      before(:each) do
        subject.inspect
      end

      it "should not call the block again" do
        subject.to_i.should == 1
      end
    end
  end

  describe "#class" do
    it "should return the class of the target object" do
      subject.class.should == target.class
    end
  end

  describe "#respond_to?" do
    it "should be true for methods on the proxy" do
      should respond_to(:reset_proxy!)
    end

    it "should be true for methods on the target object" do
      should respond_to(:inspect)
    end

    it "should be false for unimplemented methods" do
      should_not respond_to(:xxxxxxxx)
    end
  end

  describe "#reset_proxy!" do
    let(:block) { lambda { i ||= 0; i+=1 } }

    before(:each) do
      subject.inspect
    end

    it "should call the block again after being reset" do
      subject.reset_proxy!

      subject.to_i == 2
    end
  end
end