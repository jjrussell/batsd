require 'spec_helper'

describe RecommendationList do
  context '#recommendation_reject' do
    before :each do
      @device = Factory(:device)
      @options = {
        :device => @device,
        :device_type => 'iphone',
      }
      RecommendationList.stubs(:for_device).returns([])
      RecommendationList.stubs(:for_app).returns([])
      RecommendationList.stubs(:most_popular).returns([])
    end

    context 'when store id is blank' do
      it 'returns true' do
        offer = Factory(:app).primary_offer
        offer.stubs(:store_id_for_feed).returns(nil)
        puts offer.store_id_for_feed
        RecommendationList.new(@options).send(:recommendation_reject?, offer).should be_true
      end
    end
  end
end
