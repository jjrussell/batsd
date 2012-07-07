require 'spec_helper'

describe Device do
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
        param = FactoryGirl.generate(:name)
        Device.normalize_device_type(param).should be_nil
      end
    end
  end

  describe '#create_identifiers!' do
    before :each do
      @device = Factory(:device)
      @device.mac_address = 'a1b2c3d4e5f6'
      @device.android_id = 'test-android-id'
      @device.open_udid = 'test-open-udid'
      @device_identifier = Factory(:device_identifier)
    end

    it 'creates the device identifiers' do
      DeviceIdentifier.should_receive(:new).with(:key => Digest::SHA2.hexdigest(@device.key)).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => @device.open_udid).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => @device.android_id).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => @device.mac_address).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => Digest::SHA1.hexdigest(Device.formatted_mac_address(@device.mac_address))).and_return(@device_identifier)
      @device.create_identifiers!
    end

  end

  describe '#handle_sdkless_click!' do
    before :each do
      app = FactoryGirl.create :app
      @offer = app.primary_offer
      @device = FactoryGirl.create :device
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
        it "sets target app key in sdkless_clicks column to the app's app store ID" do
          @device.handle_sdkless_click!(@offer, @now)
          @device.sdkless_clicks.should have_key @offer.third_party_data
        end
      end

      context 'on an iOS device' do
        before :each do
          @offer.device_types = "[\"iphone\",\"ipad\",\"itouch\"]"
          @offer.save
        end

        context 'where a protocol_handler defined' do
          it "sets the target app key in sdkless_clicks column to the protocol_handler name" do
            @offer.item.protocol_handler = "handler.name"
            @offer.item.save
            @device.handle_sdkless_click!(@offer, @now)
            @device.sdkless_clicks.should have_key "handler.name"
          end
        end

        context "where a protocol_handler isn't defined" do
          it "sets the target app key in sdkless_clicks column to 'tjc<store_id>'" do
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

  describe '#recently_skipped?' do
    before :each do
      @device = Device.new
      @device.save!
      @key = @device.id
    end

    context 'an offer has just been skipped' do
      it 'returns true' do
        @device.recent_skips = [['a', Time.zone.now]]
        @device.recently_skipped?('a').should be_true
      end
    end

    context 'an offer has been skipped up to max time ago' do
      it 'returns true' do
        now = Time.zone.now
        @device.recent_skips = [['a', now - (Device::SKIP_TIMEOUT)]]
        Timecop.freeze(now) do
          @device.recently_skipped?('a').should be_true
        end
      end
    end

    context 'an offer has not been recently been skipped' do
      it 'returns false' do
        @device.recent_skips = [['a', Time.zone.now - (Device::SKIP_TIMEOUT + 1.second)]]
        @device.recently_skipped?('a').should be_false
      end
    end
  end

  describe '#add_skip' do
    before :each do
      @device = Device.new
      @device.save!
      @key = @device.id
    end
    it 'adds offer to recent_skips' do
      now = Time.zone.now
      @device.add_skip('a')
      Timecop.freeze(now) do
        @device.recent_skips[0][0].should == 'a'
        Time.zone.parse(@device.recent_skips[0][1]).to_i.should == now.to_i
      end
    end
    it 'retains only 100 skips' do
      105.times { |num| @device.add_skip(num) }
      @device.recent_skips.length.should == 100
    end
  end

  describe '#remove_old_skips' do
    before :each do
      @device = Device.new
      @device.save!
      @key = @device.id
    end

    it 'removes all skips more than specfied time ago' do
      a = []
      100.times do
        a << [rand(1000).to_s, Time.zone.now - rand(200).seconds]
      end
      a = a.sort_by {|item| item[1] }
      @device.recent_skips = a
      @device.recent_skips.length.should == 100
      @device.remove_old_skips(50.seconds)
      @device.recent_skips.should == []
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
      @non_jb_device = FactoryGirl.create(:device)

      @jb_device = FactoryGirl.create(:device)
      @jb_device.is_jailbroken = true
      @jb_device.stub(:save)
      @jb_device.stub(:save!)

      @app = FactoryGirl.create(:app)
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

  describe '#dashboard_device_info_tool_url' do
    include Rails.application.routes.url_helpers
    before :each do
      @device = FactoryGirl.create :device
    end

    it 'matches URL for Rails device_info_tools_url helper' do
      @device.dashboard_device_info_tool_url.should == "#{URI.parse(DASHBOARD_URL).scheme}://#{URI.parse(DASHBOARD_URL).host}/tools/device_info?udid=#{@device.key}"
    end
  end

  describe '#after_initialize' do
    before :each do
      @correct_app_ids = {'1' => Time.zone.now, '2' => Time.zone.now}
      @correct_user_ids = {'1' => 'a', '2' => 'b'}
      @device = FactoryGirl.create :device, :apps => @correct_app_ids, :publisher_user_ids => @correct_user_ids
    end

    context 'with bad app JSON data' do
      before :each do
        @device.put('apps', @correct_app_ids.to_json + "D")
      end

      it 'reads correct publisher_user_ids' do
        @device.send :after_initialize
        @device.publisher_user_ids.keys.should == @correct_user_ids.keys
      end

      it 'reads correct apps' do
        @device.send :after_initialize
        @device.apps.keys.should == @correct_app_ids.keys
      end
    end

    context 'with bad publisher user ids JSON data' do
      before :each do
        @device.put('publisher_user_ids', @correct_user_ids.to_json + "D")
      end

      it 'reads correct publisher_user_id' do
        @device.send :after_initialize
        @device.publisher_user_ids.keys.should == @correct_user_ids.keys
      end

      it 'reads correct apps' do
        @device.send :after_initialize
        @device.apps.keys.should == @correct_app_ids.keys
      end

      it 'should store correct raw data in publisher_user_ids' do
        @device.send :after_initialize
        @device.get('publisher_user_ids').should == @correct_user_ids.to_json
      end
    end
  end
end
