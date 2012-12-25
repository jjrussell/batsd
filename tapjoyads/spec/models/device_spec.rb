require 'spec_helper'

describe Device do
  before(:all) { ExperimentBucket.rehash_population(:buckets => 1, :limit => 0) }
  after(:all) { ExperimentBucket.destroy_all }

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
      @device = FactoryGirl.create(:device)
      @device.mac_address = 'a1b2c3d4e5f6'
      @device.android_id = 'test-android-id'
      @device.advertising_id = 'test-advertiser-id'
      @device_identifier = FactoryGirl.create(:device_identifier)
    end

    it 'creates the device identifiers' do
      DeviceIdentifier.should_receive(:new).with(:key => Digest::SHA2.hexdigest(@device.key)).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => Digest::SHA1.hexdigest(@device.key)).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => @device.android_id).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => @device.mac_address).and_return(@device_identifier)
      DeviceIdentifier.should_receive(:new).with(:key => Digest::SHA1.hexdigest(Device.formatted_mac_address(@device.mac_address))).and_return(@device_identifier)

      @device.should_receive(:merge_temporary_devices!).once
      @device.create_identifiers!
    end

    context 'with a temporary device' do
      before :each do
        @app_ids = {'1' => 50, '2' => 60}
        @device = FactoryGirl.create(:device, :apps => @app_ids)
        @device.send(:after_initialize)
        @temp_device = FactoryGirl.create(:temporary_device, :apps => {'2' => 55, '3' => 30},
                                          :publisher_user_ids => {'2' => 'TEST_PUB_ID'},
                                          :display_multipliers => {'2' => 3})
      end

      it 'copies the apps and deletes the temporary device' do
        TemporaryDevice.stub(:find).with(Digest::SHA2.hexdigest(@device.key)).and_return(@temp_device)
        TemporaryDevice.stub(:find).with(Digest::SHA1.hexdigest(@device.key)).and_return(nil)
        @temp_device.should_receive(:delete_all).once
        @device.should_receive(:save!).with(:create_identifiers => false)
        @device.create_identifiers!
        @device.apps.should == { '1' => 50, '2' => 55, '3' => 30 }
        @device.publisher_user_ids.should == { '2' => 'TEST_PUB_ID' }
        @device.display_multipliers.should == { '2' => 3 }
      end
    end
  end

  describe '#copy_mac_address_device!' do
    context 'without invalid data' do
      before :each do
        @device = FactoryGirl.create(:device)
        Device.should_not_receive(:new)
      end

      it 'doesnt attempt a copy' do
        @device.mac_address = ''
        @device.copy_mac_address_device!

        @device.mac_address = 'null'
        @device.copy_mac_address_device!

        @device.mac_address = @device.key
        @device.copy_mac_address_device!

        @device.key = 'null'
        @device.copy_mac_address_device!
      end
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

        context 'where a protocol_handler is defined' do
          it "sets the target app key in sdkless_clicks column to the protocol_handler name" do
            @offer.item.protocol_handler = "handler.name"
            @offer.item.save!
            @offer.app_protocol_handler(true) # re-memoize this value
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

  context 'Display multipliers' do
    before :each do
      @device = Device.new
    end

    it 'updates display_multiplier' do
      @device.set_display_multiplier('app_id', 'foo')
      @device.display_multipliers['app_id'].should == 'foo'
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

  describe '#parse_bad_json' do
    before :each do
      @correct_app_ids = {'1' => Time.zone.now.to_i, '2' => Time.zone.now.to_i}
      @device = FactoryGirl.create :device, :apps => @correct_app_ids
    end

    context 'with absolute garbage' do
      it 'raises a parse error' do
        @device.put('apps', '{d{}ds{[]}}}}ds[}}{"here":"is","some":"json"}{{more}[garbage[[}}')

        expect {
          @device.send(:parse_bad_json, 'apps')
        }.to raise_exception(JSON::ParserError)
      end
    end

    context 'with extra chars at the end' do
      before :each do
        @device.put('apps', @correct_app_ids.to_json + "D")
      end

      it 'returns proper JSON' do
        expect {
          @device.send(:parse_bad_json, 'apps')
        }.to_not raise_exception
      end

      it 'returns correct data' do
        @device.send(:parse_bad_json, 'apps').should == @correct_app_ids
      end
    end

    context 'with missing end-bracket' do
      before :each do
        @device.put('apps', @correct_app_ids.to_json[0..-2])
      end

      it 'returns properJSON' do
        expect {
          @device.send(:parse_bad_json, 'apps')
        }.to_not raise_exception
      end

      it 'returns mostly correct data' do
        @device.send(:parse_bad_json, 'apps').each do |key, value|
          value.should == @correct_app_ids[key]
        end
      end
    end

    context 'with extra JSON after end-bracket (or an early end-bracket, depending on your point of view)' do
      context 'containing a new key' do
        before(:each) do
          # the 'extra json' can/will be missing the open {
          @device.put('apps', @correct_app_ids.to_json + '"extra_key":"extra_val"}')
        end

        it 'returns proper JSON' do
          expect {
            @device.send(:parse_bad_json, 'apps', :right)
          }.to_not raise_exception
        end

        it 'includes the extra JSON in the parsed hash' do
          @device.send(:parse_bad_json, 'apps', :right)['extra_key'].should == 'extra_val'
        end
      end

      context 'containing a duplicate key' do
        before(:each) do
          @device.put('apps',
            @correct_app_ids.to_json +
            {@correct_app_ids.keys.first => 'bad'}.to_json
          )
        end

        it 'will not overwrite values in the good JSON with values from the extra JSON' do
          @device.send(:parse_bad_json, 'apps', :right).each do |key, value|
            value.should == @correct_app_ids[key]
          end
        end
      end

      context 'containing invalid JSON' do
        before(:each) do
          # the 'extra json' is terribly malformed
          @device.put('apps',
            @correct_app_ids.to_json + '"extra_key":extra_val"}'
          )
        end

        it 'will discard the extra, invalid JSON' do
          expect {
            @device.send(:parse_bad_json, 'apps', :right).each do |key, value|
              value.should == @correct_app_ids[key]
            end
          }.to_not raise_exception
        end
      end
    end
  end

  describe '#save' do
    context 'for a new device' do
      let(:device) { Device.new(:key => FactoryGirl.generate(:guid)) }

      it 'creates the identifiers' do
        Sqs.should_receive(:send_message).with(QueueNames::CREATE_DEVICE_IDENTIFIERS, {'device_id' => device.key}.to_json)
        device.save
      end

      it 'doesnt create the identifers if specified' do
        Sqs.should_not_receive(:send_message)
        device.save(:create_identifiers => false)
      end
    end

    context 'for an existing device' do
      let(:device) { Device.new(:key => FactoryGirl.generate(:guid)).tap(&:save) }

      it 'does not assign an experiment bucket' do
        device.should_not_receive(:assign_experiment_bucket)
        device.save
      end
    end

    context 'for a temporary device' do
      before :each do
        @device = Device.new(:key => 'test_udid', :is_temporary => true)
        @device.set_last_run_time('1')
        @device.set_last_run_time('3')
        @time = @device.parsed_apps['3']
        @device.set_publisher_user_id('1', 'TEST_PUB_USER_ID')
        @device.set_publisher_user_id('3', 'TEST_PUB_USER_ID_NEW')
        @device.set_display_multiplier('1', 2)
        @temp_device = FactoryGirl.create(:temporary_device,
                                          :apps => {'2' => 55, '3' => 60},
                                          :publisher_user_ids => {'2' => 'PUB_USER_ID', '3' => 'TEST_PUB_OLD'},
                                          :display_multipliers => {'2' => '1'})
      end

      it 'tries to save a temporary device' do
        TemporaryDevice.should_receive(:new).with(:key => 'test_udid').and_return(@temp_device)
        @temp_device.should_receive(:save)
        Sqs.should_not_receive(:send_message)
        @device.save
        @temp_device.apps.should include('1')
        @temp_device.apps.should include('2')
        @temp_device.apps.should include('3')
        @temp_device.apps['3'].should == @time

        @temp_device.publisher_user_ids.should include('1')
        @temp_device.publisher_user_ids.should include('2')
        @temp_device.publisher_user_ids.should include('3')
        @temp_device.publisher_user_ids['3'].should == 'TEST_PUB_USER_ID_NEW'

        @temp_device.display_multipliers.should include('1')
        @temp_device.display_multipliers.should include('2')
      end
    end

    context 'for a device with more than Device::APP_LIMIT apps' do
      it 'keeps only the Device::APP_LIMIT most recent apps' do
        stub_const("Device::APP_LIMIT", 20)
        too_many = Device::APP_LIMIT + 20
        device = FactoryGirl.create(:device)
        too_many.times { |app| device.set_last_run_time(app.to_s) }
        device.apps.count.should == too_many
        device.save
        device.apps.count.should == Device::APP_LIMIT
      end
    end
  end

  describe '#after_initialize' do
    before :each do
      @correct_app_ids = {'1' => Time.zone.now.to_i, '2' => Time.zone.now.to_i}
      @correct_user_ids = {'1' => '{a}', '2' => 'b'}
      @device = FactoryGirl.create :device, :apps => @correct_app_ids, :publisher_user_ids => @correct_user_ids
    end

    context 'for a temporary device' do
      before :each do
        @device = Device.new(:key => 'test_udid', :is_temporary => true)
        @temp_device = FactoryGirl.create(:temporary_device,
                       :apps => {'2' => 50},
                       :publisher_user_ids => {'2' => 'PUB_ID_TEST'},
                       :display_multipliers => {'2' => 3})
      end

      it 'should load apps from temporary devices' do
        TemporaryDevice.should_receive(:new).with(:key => @device.key).and_return(@temp_device)
        @device.send :after_initialize
        @device.apps.should == {'2' => 50}
        @device.publisher_user_ids.should == {'2' => 'PUB_ID_TEST'}
        @device.display_multipliers.should == {'2' => 3}
      end
    end

    context 'with bad app JSON data' do
      before :each do
        @device.put('apps', @correct_app_ids.to_json + "D")
      end

      it 'reads correct publisher_user_ids' do
        @device.send :after_initialize
        @device.publisher_user_ids.should == @correct_user_ids
      end

      it 'reads correct apps' do
        @device.send :after_initialize
        @device.apps.should == @correct_app_ids
      end
    end

    context 'with bad publisher user ids JSON data' do
      before :each do
        @device.put('publisher_user_ids', @correct_user_ids.to_json + "D")
      end

      it 'reads correct publisher_user_id' do
        @device.send :after_initialize
        @device.publisher_user_ids.should == @correct_user_ids
      end

      it 'reads correct apps' do
        @device.send :after_initialize
        @device.apps.should == @correct_app_ids
      end

      it 'should store correct raw data in publisher_user_ids' do
        @device.send :after_initialize
        @device.get('publisher_user_ids').should == @correct_user_ids.to_json
      end
    end
  end

  describe '#suspend!' do
    before :each do
      @now = Time.now
      Timecop.freeze(@now)
      @device = FactoryGirl.create(:device)
    end

    it 'marks device suspended' do
      @device.suspend!(24)
      @device.suspended?.should be_true
    end

    it 'expires suspension after specified time' do
      @device.suspend!(24)
      Timecop.freeze(@now+25.hours)
      @device.suspended?.should be_false
    end

    after :each do
      Timecop.return
    end
  end

  describe '#unsuspend!' do
    it "unsuspends device" do
      @device = FactoryGirl.create(:device)
      @device.suspend!(24)
      @device.suspended?.should be_true
      @device.unsuspend!
      @device.suspended?.should be_false
    end
  end

  describe '#set_pending_coupon' do
    before :each do
      @device = FactoryGirl.create(:device)
      @device.stub(:save).and_return(true)
      @device.set_pending_coupon('123456')
    end

    it 'should have an array with offer id' do
      @device.pending_coupons.should include('123456')
    end
  end

  describe '#remove_pending_coupon' do
    before :each do
      @device = FactoryGirl.create(:device)
      @device.stub(:save).and_return(true)
      @device.set_pending_coupon('123')
      @device.set_pending_coupon('456')
      @device.remove_pending_coupon('123')
    end

    it 'should have an array with offer id' do
      @device.pending_coupons.should include('456')
    end
  end

  describe '#in_network_apps' do
    before :each do
      @app1 = FactoryGirl.create :app
      FactoryGirl.create(:currency, :app_id => @app1.id, :callback_url => 'http://foo.com')

      @app2 = FactoryGirl.create :app
      FactoryGirl.create(:currency, :app_id => @app2.id, :callback_url => 'http://foo.com')

      ext_pub1 = ExternalPublisher.new(@app1.currencies.first)
      ext_pub2 = ExternalPublisher.new(@app2.currencies.first)

      external_publishers = [ ext_pub1, ext_pub2 ]
      ExternalPublisher.stub(:load_all_for_device).and_return(external_publishers)

      InNetworkApp.stub(:new).and_return(mock('in_network_app'))
      @device = FactoryGirl.create :device
      @device.set_last_run_time!(@app1.id)
      @device.set_last_run_time!(@app2.id)
    end

    it 'return in_network_apps based on device.apps' do
      @device.in_network_apps.size.should == 2
    end
  end
end
