require 'spec_helper'

describe ExternalPublisher do
  context '#get_offerwall_url' do
    before :each do
      I18n.stub(:locale).and_return('en')
      HeaderParser.stub(:device_type).and_return('iphone')
      HeaderParser.stub(:os_version).and_return('ios')
      @app = double('app', :name => 'test', :partner_name => 'bert', :active_gamer_count => 5, :primary_app_metadata => FactoryGirl.create(:app_metadata))
      @curr = double('currency', :app_id => '1234', :app => @app,
                     :id => 99, :name => 'dollars', :udid_for_user_id => 'udid', :tapjoy_managed? => true )
      @device = double('device')
      @currency = {:id => 'dollars'}
      @accept_language_str = 'en'
      @user_agent_str = 'ag_str'
      @gamer_id = 'test'
      @no_log = false
    end

    it 'succeeds without a publisher_user_id' do
      @device.stub(:publisher_user_ids).and_return({})
      @device.stub(:display_multipliers).and_return({})
      @device.stub(:key).and_return('123')
      url = ExternalPublisher.new(@curr)
      test = url.get_offerwall_url(@device, @currency, @accept_language_str, @user_agent_str, @gamer_id, @no_log)
      decrypted_url = ObjectEncryptor.decrypt(test.match(/.*data=(.*)/)[1])
      decrypted_url.should include(
        :tapjoy_device_id   => @device.key,
        :publisher_user_id  => @device.key,
        :currency_id        => @currency[:id],
        :display_multiplier => '1'
      )
    end

    it 'succeeds with a publisher_user_id and without a publisher_multiplier' do
      @device.stub(:publisher_user_ids).and_return( {'1234' => 'username'} )
      @device.stub(:display_multipliers).and_return({})
      @device.stub(:key).and_return('123')
      url = ExternalPublisher.new(@curr)
      test = url.get_offerwall_url(@device, @currency, @accept_language_str, @user_agent_str, @gamer_id, @no_log)
      decrypted_url = ObjectEncryptor.decrypt(test.match(/.*data=(.*)/)[1])
      decrypted_url.should include(
        :tapjoy_device_id   => @device.key,
        :publisher_user_id  => 'username',
        :currency_id        => @currency[:id],
        :display_multiplier => '1'
      )
    end

    it 'succeeds with a publisher_user_id and a publisher_multiplier' do
      @device.stub(:publisher_user_ids).and_return( {'1234' => 'username'} )
      @device.stub(:display_multipliers).and_return({'1234' => '4'})
      @device.stub(:key).and_return('123')
      url = ExternalPublisher.new(@curr)
      test = url.get_offerwall_url(@device, @currency, @accept_language_str, @user_agent_str, @gamer_id, @no_log)
      decrypted_url = ObjectEncryptor.decrypt(test.match(/.*data=(.*)/)[1])
      decrypted_url.should include(
        :tapjoy_device_id   => @device.key,
        :publisher_user_id  => 'username',
        :currency_id        => @currency[:id],
        :display_multiplier => '4'
      )
    end
  end
end
