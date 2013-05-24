require 'spec_helper'

describe Job::QueueCreateConversionsController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)

    @publisher_app = FactoryGirl.create(:app)
    advertiser_app = FactoryGirl.create(:app)
    @offer = advertiser_app.primary_offer
    @click = FactoryGirl.create(:click, :ip_address => '127.0.0.1')
    @reward = FactoryGirl.create(:reward,
      :type                  => 'offer',
      :publisher_app_id      => @publisher_app.id,
      :advertiser_app_id     => advertiser_app.id,
      :offer_id              => @offer.id,
      :publisher_partner_id  => @publisher_app.partner_id,
      :advertiser_partner_id => advertiser_app.partner_id,
      :publisher_amount      => 1,
      :advertiser_amount     => 1,
      :tapjoy_amount         => 1,
      :udid                  => 'udid')
    Reward.should_receive(:find).with('reward_key', :consistent => true).and_return(@reward)
    @reward.stub(:offer).and_return(@offer)
    @reward.stub(:click).and_return(@click)
  end

  context 'without conversion tracking urls' do
    it 'does not enqueue conversion tracking GET requests' do
      @offer.should_not_receive(:queue_conversion_tracking_requests)

      get(:run_job, :message => 'reward_key')
    end
  end

  context 'with conversion tracking urls' do
    before :each do
      @offer.update_attributes!(:conversion_tracking_urls => 'http://www.example.com')
    end

    context 'when conversions already exist' do
      it 'doesnt queue third party tracking' do
        Conversion.any_instance.stub(:save!).and_raise(ActiveRecord::StatementInvalid)
        Conversion.any_instance.stub(:errors).and_return(:id =>['has already been taken'])
        @offer.should_not_receive(:queue_conversion_tracking_requests)
        get(:run_job, :message => 'reward_key')
      end
    end

    it 'enqueues conversion tracking GET requests properly' do
      @offer.should_receive(:queue_conversion_tracking_requests).with(
        :timestamp        => @reward.created.to_i,
        :ip_address       => @click.ip_address,
        :udid             => 'udid',
        :publisher_app_id => @publisher_app.id).once

      get(:run_job, :message => 'reward_key')
    end
  end
end
