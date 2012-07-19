require 'spec_helper'

describe Job::QueueCreateConversionsController do
  before :each do
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)

    publisher_app = FactoryGirl.create(:app)
    advertiser_app = FactoryGirl.create(:app)
    @offer = advertiser_app.primary_offer
    @reward = FactoryGirl.create(:reward,
      :type => 'offer',
      :publisher_app_id => publisher_app.id,
      :advertiser_app_id => advertiser_app.id,
      :offer_id => @offer.id,
      :publisher_partner_id => publisher_app.partner_id,
      :advertiser_partner_id => advertiser_app.partner_id,
      :publisher_amount => 1,
      :advertiser_amount => 1,
      :tapjoy_amount => 1)
    Reward.should_receive(:find).with('reward_key', :consistent => true).and_return(@reward)
    @reward.stub(:offer).and_return(@offer)
  end

  it 'enqueues conversion tracking GET requests properly' do
    @offer.should_receive(:queue_conversion_tracking_requests).with(@reward.created.to_i).once

    get(:run_job, :message => 'reward_key')
  end
end
