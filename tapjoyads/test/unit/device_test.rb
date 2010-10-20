require 'test_helper'

class DeviceTest < ActiveSupport::TestCase
  
  context "A Device" do
    setup do
     @device = Device.new
     @device.save!
     @key = @device.id
     sleep 0.5 # give SimpleDB time to save
    end
    
    should "be correctly found when searched by id" do
      assert_equal @device, Device.find(@key)
      assert_equal @device, Device.find_by_id(@key)
      assert_equal @device, Device.find_all_by_id(@key).first
    end
    
    should "be correctly found when searched by where conditions" do
      assert_equal @device, Device.find(:first, :where => "itemname() = '#{@key}'")
      assert_equal @device, Device.find(:all, :where => "itemname() = '#{@key}'").first
    end
  end
  
  context "A Device" do
    setup do
      @device = Device.new
      @key = @device.id
    end
    
    should "not be found when it doesn't exist" do
      assert_nil Device.find(:first, :where => "itemname() = '#{@key}'")
    end
  end
  
  context "Multiple new Devices" do
    setup do
      @count = Device.count
      @num = 5
      @num.times { Device.new.save! }
      sleep 0.5
    end
    
    should "be counted correctly" do
      assert_equal @count + @num, Device.count
    end
    
    should "be counted correctly per-domain" do
      sum = 0
      Device.all_domain_names.each do |name|
        sum += Device.count(:domain_name => name)
      end
      assert_equal @count + @num, sum
    end
  end
  
end
