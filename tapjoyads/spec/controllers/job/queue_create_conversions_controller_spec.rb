require 'spec/spec_helper'

describe Job::QueueCreateConversionsController do
  before :each do
    fake_the_web
    @controller.expects(:authenticate).at_least_once.returns(true)

    publisher_app = Factory(:app)
    advertiser_app = Factory(:app)
    @offer = advertiser_app.primary_offer
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
    @reward.stubs(:offer).returns(@offer)
    Reward.expects(:find).with('reward_key', :consistent => true).returns(@reward)
  end

  it 'enqueues conversion tracking GET requests properly' do
    @offer.expects(:queue_conversion_tracking_requests).with(@reward.created.to_i.to_s).once

    get(:run_job, :message => 'reward_key')
  end
end
