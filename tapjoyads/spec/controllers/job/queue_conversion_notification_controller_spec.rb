require 'spec_helper'

describe Job::QueueConversionNotificationsController do
  before :each do
   @controller.should_receive(:authenticate).at_least(:once).and_return(true)
   @currency = Factory.create(:currency)
   @publisher_app = FactoryGirl.create(:app)
   @advertiser_app = FactoryGirl.create(:app)
   @offer = @advertiser_app.primary_offer

   @reward = FactoryGirl.create(:reward,
      :type                  => 'offer',
      :publisher_app_id      => @publisher_app.id,
      :advertiser_app_id     => @advertiser_app.id,
      :offer_id              => @offer.id,
      :publisher_partner_id  => @publisher_app.partner_id,
      :advertiser_partner_id => @advertiser_app.partner_id,
      :publisher_amount      => 1,
      :advertiser_amount     => 1,
      :tapjoy_amount         => 1,
      :currency_id           => @currency.id,
      :udid                  => 'udid'
    )

    @notification = NotificationsClient::Notification.new({
      :app_id => @reward.publisher_app_id,
      :title => "Reward Notification",
      :message => "Your reward from #{@publisher_app.name} is available!",
      :device_aliases => [{:identifier => @reward.udid, :namespace => 'default'}]
      })
  end

  context "sending" do
    before(:each) do
      NotificationsClient::Notification.any_instance.stub(:deliver)

      @device = Device.new(:key => 'udid')
      @device.idfa = 'idfa'
      @device.android_id = 'android_id'
      @device.save
    end

    it "should find reward" do
      Reward.should_receive(:find).with(@reward.key, :consistent => true).and_return(@reward)
      get(:run_job, :message => @reward.key)
    end

    it "should create a Notification object" do
      NotificationsClient::Notification.should_receive(:new).with({
        :app_id => @reward.publisher_app_id,
        :app_secret_key => @publisher_app.secret_key,
        :title => "Reward Notification",
        :message => "You earned #{@reward.currency_reward} #{@currency.name} by downloading #{@advertiser_app.name}",
        :throttle_key => 'tjofferconversion',
        :device_aliases => [{:device_key => 'udid', :android_id => 'android_id', :idfa => 'idfa'}]
      }).and_return(@notification)

      get(:run_job, :message => @reward.key)
    end

    it "should upcase and perform SHA1 hexdigest of mac_address" do
      @device.mac_address = 'd023dbb1e858'
      @device.save

      NotificationsClient::Notification.should_receive(:new).with({
        :app_id => @reward.publisher_app_id,
        :app_secret_key => @publisher_app.secret_key,
        :title => "Reward Notification",
        :message => "You earned #{@reward.currency_reward} #{@currency.name} by downloading #{@advertiser_app.name}",
        :throttle_key => 'tjofferconversion',
        :device_aliases => [{:device_key => 'udid', :android_id => 'android_id', :mac_sha1 => '1f22542dc51c54db355649323bc7792fbcea94a9', :idfa => 'idfa'}]
      }).and_return(@notification)

      get(:run_job, :message => @reward.key)
    end

    it "should deliver a notification" do
      NotificationsClient::Notification.any_instance.should_receive(:deliver)
      get(:run_job, :message => @reward.key)
    end
  end
end
