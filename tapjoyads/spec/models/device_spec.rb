require 'spec_helper'

describe Device do
  before :each do
    SimpledbResource.reset_connection
  end

  context "A Device" do
    before :each do
     @device = Device.new
     @device.save!
     @key = @device.id
    end

    it "should be correctly found when searched by id" do
      Device.find(@key, :consistent => true).should == @device
      Device.find_by_id(@key, :consistent => true).should == @device
      Device.find_all_by_id(@key, :consistent => true).first.should == @device
    end

    it "should be correctly found when searched by where conditions" do
      Device.find(:first, :where => "itemname() = '#{@key}'", :consistent => true).should == @device
      Device.find(:all, :where => "itemname() = '#{@key}'", :consistent => true).first.should == @device
    end
  end

  context "A Device" do
    before :each do
      @device = Device.new
      @key = @device.id
    end

    it "should not be found when it doesn't exist" do
      Device.find(:first, :where => "itemname() = '#{@key}'").should be_nil
    end
  end

  context "Multiple new Devices" do
    before :each do
      @count = Device.count(:consistent => true)
      @num = 5
      @num.times { Device.new.save! }
    end

    it "should be counted correctly" do
      Device.count(:consistent => true).should == @count + @num
    end

    it "should be counted correctly per-domain" do
      sum = 0
      Device.all_domain_names.each do |name|
        sum += Device.count(:domain_name => name, :consistent => true)
      end
      sum.should == @count + @num
    end
  end

  context "Publisher user ids" do
    before :each do
      @device = Device.new
    end

    it "should update publisher_user_id" do
      @device.set_publisher_user_id('app_id', 'foo')
      @device.publisher_user_ids['app_id'].should == 'foo'
    end
  end

  context "Jailbreak detection" do
    before :each do
      @non_jb_device = Factory(:device)

      @jb_device = Factory(:device)
      @jb_device.is_jailbroken = true
      @jb_device.stubs(:save)
      @jb_device.stubs(:save!)

      @app = Factory(:app)
    end

    it "should mark as not jb when lad is 0" do
      @jb_device.handle_connect!(@app.id, { :lad => '0' })
      @non_jb_device.handle_connect!(@app.id, { :lad => '0' })

      @jb_device.is_jailbroken?.should be_false
      @non_jb_device.is_jailbroken?.should be_false
    end

    it "should mark as jb when lad is non-zero" do
      @jb_device.handle_connect!(@app.id, { :lad => '42' })
      @non_jb_device.handle_connect!(@app.id, { :lad => '42' })

      @jb_device.is_jailbroken?.should be_true
      @non_jb_device.is_jailbroken?.should be_true
    end

    it "should not change jb when lad is not present" do
      @jb_device.handle_connect!(@app.id, { })
      @non_jb_device.handle_connect!(@app.id, { })

      @jb_device.is_jailbroken?.should be_true
      @non_jb_device.is_jailbroken?.should be_false
    end

    it "should mark as jb when it's a new papaya user" do
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})
      @non_jb_device.is_jailbroken?.should be_true
    end

    it "should not change jb status when it's an existing papaya user" do
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})

      # should still be jb
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})
      @non_jb_device.is_jailbroken?.should be_true

      # now marked as not jb
      @non_jb_device.handle_connect!(@app.id, { :lad => '0' })
      @non_jb_device.is_jailbroken?.should be_false

      # second time around, should not mark as jb again
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})
      @non_jb_device.is_jailbroken?.should be_false
    end
  end
end
