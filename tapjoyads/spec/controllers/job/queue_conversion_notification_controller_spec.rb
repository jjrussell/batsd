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
    
    @device = Device.new(:key => 'udid')
    @device.idfa = 'idfa'
    @device.android_id = 'android_id'
    @device.save
  end

  context "sending" do
    before(:each) do
      NotificationsClient::Notification.any_instance.stub(:deliver)
    end

    it "should find reward" do
      Reward.should_receive(:find).with(@reward.key, :consistent => true).and_return(@reward)
      get(:run_job, :message => @reward.key)
    end

    it "should create a Notification object" do
      NotificationsClient::Notification.should_receive(:new).with({
        :app_id => @reward.publisher_app_id,
        :title => "Reward Notification",
        :message => "You earned #{@currency.name} by downloading #{@advertiser_app.name}",
        :device_aliases => [{:namespace => 'android_id', :identifier => 'android_id'}, {:namespace => 'idfa', :identifier => 'idfa'}]
      }).and_return(@notification)

      get(:run_job, :message => @reward.key)
    end
  end
end
