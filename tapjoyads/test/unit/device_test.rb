require 'test_helper'

class DeviceTest < ActiveSupport::TestCase

  context "A Device" do
    setup do
     @device = Device.new
     @device.save!
     @key = @device.id
    end

    should "be correctly found when searched by id" do
      assert_equal @device, Device.find(@key, :consistent => true)
      assert_equal @device, Device.find_by_id(@key, :consistent => true)
      assert_equal @device, Device.find_all_by_id(@key, :consistent => true).first
    end

    should "be correctly found when searched by where conditions" do
      assert_equal @device, Device.find(:first, :where => "itemname() = '#{@key}'", :consistent => true)
      assert_equal @device, Device.find(:all, :where => "itemname() = '#{@key}'", :consistent => true).first
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
      @count = Device.count(:consistent => true)
      @num = 5
      @num.times { Device.new.save! }
    end

    should "be counted correctly" do
      assert_equal @count + @num, Device.count(:consistent => true)
    end

    should "be counted correctly per-domain" do
      sum = 0
      Device.all_domain_names.each do |name|
        sum += Device.count(:domain_name => name, :consistent => true)
      end
      assert_equal @count + @num, sum
    end
  end


  context "Jailbreak detection" do
    setup do
      @non_jb_device = Factory(:device)

      @jb_device = Factory(:device)
      @jb_device.is_jailbroken = true
      @jb_device.stubs(:save)
      @jb_device.stubs(:save!)

      @app = Factory(:app)
    end

    should "mark as not jb when lad is 0" do
      @jb_device.handle_connect!(@app.id, { :lad => '0' })
      @non_jb_device.handle_connect!(@app.id, { :lad => '0' })

      assert !@jb_device.is_jailbroken?
      assert !@non_jb_device.is_jailbroken?
    end

    should "mark as jb when lad is non-zero" do
      @jb_device.handle_connect!(@app.id, { :lad => '42' })
      @non_jb_device.handle_connect!(@app.id, { :lad => '42' })

      assert @jb_device.is_jailbroken?
      assert @non_jb_device.is_jailbroken?
    end

    should "not change jb when lad is not present" do
      @jb_device.handle_connect!(@app.id, { })
      @non_jb_device.handle_connect!(@app.id, { })

      assert @jb_device.is_jailbroken?
      assert !@non_jb_device.is_jailbroken?
    end

    should "mark as jb when it's a new papaya user" do
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})
      assert @non_jb_device.is_jailbroken?
    end

    should "not change jb status when it's an existing papaya user" do
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})

      # should still be jb
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})
      assert @non_jb_device.is_jailbroken?

      # now marked as not jb
      @non_jb_device.handle_connect!(@app.id, { :lad => '0' })
      assert !@non_jb_device.is_jailbroken?

      # second time around, should not mark as jb again
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})
      assert !@non_jb_device.is_jailbroken?
    end
  end
end
