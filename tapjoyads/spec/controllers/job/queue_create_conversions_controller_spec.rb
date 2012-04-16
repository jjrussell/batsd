require 'spec/spec_helper'

def json_message(url = nil)
  { :reward_key => 'reward_key', :request_url => url }.to_json
end

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

  # remove this once we're sure all remaining queue message are json-encoded
  it 'still works without a json-encoded message' do
    get(:run_job, :message => 'reward_key')
  end

  context 'with a json-encoded message' do
    context 'with an offer with conversion_tracking_urls' do
      before :each do
        @offer.conversion_tracking_urls = %w(http://www.example.com)
        @reward.stubs(:created).returns(Time.zone.now.to_f.to_s)
      end

      context 'with a \'request_url\' parameter' do
        it 'should use \'request_url\' as the referer url' do
          test_url = 'http://williamshat.com'
          message = json_message(test_url)
          Reward.expects(:find).with(message, :consistent => true).returns(nil)
          @offer.expects(:queue_conversion_tracking_requests).with(test_url, @reward.created.to_i.to_s).once

          get(:run_job, :message => message)
        end
      end

      context 'without a \'request_url\' parameter' do
        it 'should use a default url for the referer url' do
          message = json_message
          Reward.expects(:find).with(message, :consistent => true).returns(nil)
          @offer.expects(:queue_conversion_tracking_requests).with('https://api.tapjoy.com/connect', @reward.created.to_i.to_s).once

          get(:run_job, :message => message)
        end
      end
    end
  end
end
