require 'spec/spec_helper'

describe Job::QueueCreateConversionsController do
  before :each do
    fake_the_web
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)

    publisher_app = Factory(:app)
    advertiser_app = Factory(:app)
    @offer = advertiser_app.primary_offer
    Offer.stub(:find).and_return(@offer)
    @reward = Factory(:reward,
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
  end

  it 'enqueues conversion tracking GET requests properly' do
    @offer.should_receive(:queue_conversion_tracking_requests).with(@reward.created.to_i.to_s).once

    get(:run_job, :message => 'reward_key')
  end
end
