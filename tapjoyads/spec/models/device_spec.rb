require 'spec_helper'

describe Device do
  before :each do
    SimpledbResource.reset_connection
  end

  describe '.normalize_device_type' do
    context 'type is iPhone' do
      it 'returns iphone' do
        param = 'iPhone'
        Device.normalize_device_type(param).should == 'iphone'
      end
    end

    context 'type is iPod' do
      it 'returns itouch' do
        param = 'iPod'
        Device.normalize_device_type(param).should == 'itouch'
      end
    end

    context 'type is iTouch' do
      it 'returns itouch' do
        param = 'iTouch'
        Device.normalize_device_type(param).should == 'itouch'
      end
    end

    context 'type is iPad' do
      it 'returns ipad' do
        param = 'iPad'
        Device.normalize_device_type(param).should == 'ipad'
      end
    end

    context 'type is Android' do
      it 'returns android' do
        param = 'Android'
        Device.normalize_device_type(param).should == 'android'
      end
    end

    context 'type is Windows' do
      it 'returns windows' do
        param = 'Windows'
        Device.normalize_device_type(param).should == 'windows'
      end
    end

    context 'type is something else' do
      it 'returns nil' do
        param = Factory.next(:name)
        Device.normalize_device_type(param).should be_nil
      end
    end
  end

  describe '#handle_sdkless_click!' do
    before :each do
      app = Factory :app
      @offer = app.primary_offer
      @device = Factory :device
      @now = Time.zone.now
    end

    context 'when an SDK-less app offer is clicked' do
      before :each do
        @offer.device_types = "[\"android\"]"
        @offer.sdkless = true
        @offer.save
        @device.sdkless_clicks = { 'package1' => { 'click_time' => (Time.zone.now - 1.day).to_i, 'item_id' => 'click1' },
                                   'package2' => { 'click_time' => (Time.zone.now - 3.days).to_i, 'item_id' => 'click2' }}
        @device.save
      end

      it "adds the click timestamp to the target app's entry in sdkless_clicks" do
        @device.handle_sdkless_click!(@offer, @now)
        @device.sdkless_clicks[@offer.third_party_data]['click_time'].should == @now.to_i
      end

      it "adds the target app's ID to the entry in sdkless_clicks" do
        @device.handle_sdkless_click!(@offer, @now)
        @device.sdkless_clicks[@offer.third_party_data]['item_id'].should == @offer.item_id
      end

      it 'retains SDK-less clicks that are less than 2 days old' do
        @device.handle_sdkless_click!(@offer, @now)
        @device.sdkless_clicks.should have_key 'package1'
      end

      it 'discards SDK-less clicks that are more than 2 days old' do
        @device.handle_sdkless_click!(@offer, @now)
        @device.sdkless_clicks.should_not have_key 'package2'
      end

      context 'on an Android device' do
        it "sets key for the target app in sdkless_clicks column of the device model to the app's app store ID" do
          @device.handle_sdkless_click!(@offer, @now)
          @device.sdkless_clicks.should have_key @offer.third_party_data
        end
      end

      context 'on an iOS device' do
        before :each do
          @offer.device_types = "[\"iphone\",\"ipad\",\"itouch\"]"
          @offer.save
        end

        context 'where the app has a protocol_handler defined' do
          it "sets the key for the target app in sdkless_clicks column of the device model to the protocol_handler name"
        end

        context "where the app doesn't have a protocol_handler defined" do
          it "sets the key for the target app in sdkless_clicks column of the device model to 'tjc<store_id>'" do
            @device.handle_sdkless_click!(@offer, @now)
            @device.sdkless_clicks.should have_key "tjc#{@offer.third_party_data}"
          end
        end
      end
    end

    context 'when a non-SDK-less app offer is clicked' do
      before :each do
        @offer.sdkless = false
        @offer.save
        @device.handle_sdkless_click!(@offer, @now)
      end

      it "doesn't add anything to the sdkless_clicks column of the device model" do
        @device.sdkless_clicks.should_not have_key @offer.third_party_data
      end
    end
  end

  context 'A Device' do
    before :each do
     @device = Device.new
     @device.save!
     @key = @device.id
    end

    it 'is correctly found when searched by id' do
      Device.find(@key, :consistent => true).should == @device
      Device.find_by_id(@key, :consistent => true).should == @device
      Device.find_all_by_id(@key, :consistent => true).first.should == @device
    end

    it 'is correctly found when searched by where conditions' do
      Device.find(:first, :where => "itemname() = '#{@key}'", :consistent => true).should == @device
      Device.find(:all, :where => "itemname() = '#{@key}'", :consistent => true).first.should == @device
    end
  end

  context 'A Device' do
    before :each do
      @device = Device.new
      @key = @device.id
    end

    it "is not found when it doesn't exist" do
      Device.find(:first, :where => "itemname() = '#{@key}'").should be_nil
    end
  end

  context 'Publisher user ids' do
    before :each do
      @device = Device.new
    end

    it 'updates publisher_user_id' do
      @device.set_publisher_user_id('app_id', 'foo')
      @device.publisher_user_ids['app_id'].should == 'foo'
    end
  end

  context 'Jailbreak detection' do
    before :each do
      @non_jb_device = Factory(:device)

      @jb_device = Factory(:device)
      @jb_device.is_jailbroken = true
      @jb_device.stubs(:save)
      @jb_device.stubs(:save!)

      @app = Factory(:app)
    end

    it 'marks as not jb when lad is 0' do
      @jb_device.handle_connect!(@app.id, { :lad => '0' })
      @non_jb_device.handle_connect!(@app.id, { :lad => '0' })

      @jb_device.is_jailbroken?.should be_false
      @non_jb_device.is_jailbroken?.should be_false
    end

    it 'marks as jb when lad is non-zero' do
      @jb_device.handle_connect!(@app.id, { :lad => '42' })
      @non_jb_device.handle_connect!(@app.id, { :lad => '42' })

      @jb_device.is_jailbroken?.should be_true
      @non_jb_device.is_jailbroken?.should be_true
    end

    it 'does not change jb when lad is not present' do
      @jb_device.handle_connect!(@app.id, { })
      @non_jb_device.handle_connect!(@app.id, { })

      @jb_device.is_jailbroken?.should be_true
      @non_jb_device.is_jailbroken?.should be_false
    end

    it "marks as jb when it's a new papaya user" do
      @non_jb_device.handle_connect!('e96062c5-45f0-43ba-ae8f-32bc71b72c99', {})
      @non_jb_device.is_jailbroken?.should be_true
    end

    it "does not change jb status when it's an existing papaya user" do
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
