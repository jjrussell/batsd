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
    @click = Factory(:click)
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
    @reward.stubs(:click).returns(@click)
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
        @click.x_do_not_track_header = '1'
        @click.dnt_header = '1'
        @click.user_agent_header = 'Firefox'

        @http_request = ActionController::Request.new({})

        ActionController::Request.expects(:new).returns(@http_request)

        @offer.conversion_tracking_urls = %w(http://www.example.com)
        now = Time.zone.now
        @reward.stubs(:created).returns(now)
        @offer.expects(:queue_conversion_tracking_requests).with(@http_request, now.to_i.to_s).once
      end

      after :each do
        @http_request.http_headers.should == { 'X-Do-Not-Track' => @click.x_do_not_track_header,
          'User-Agent' => @click.user_agent_header, 'Dnt' => @click.dnt_header }
      end

      context 'with a \'request_url\' parameter' do
        it 'should use \'request_url\' as the http request\'s url' do
          test_url = 'http://williamshat.com'
          message = json_message(test_url)
          Reward.expects(:find).with(message, :consistent => true).returns(nil)

          get(:run_job, :message => message)
          @http_request.url.should == test_url # make sure 'url' method was re-defined
        end
      end

      context 'without a \'request_url\' parameter' do
        it 'should use a default url for the http request\'s url' do
          default_url = 'https://api.tapjoy.com/connect' # should match url hard-coded in the controller
          message = json_message
          Reward.expects(:find).with(message, :consistent => true).returns(nil)

          get(:run_job, :message => message)
          @http_request.url.should == default_url # make sure 'url' method was re-defined
        end
      end
    end
  end
end
