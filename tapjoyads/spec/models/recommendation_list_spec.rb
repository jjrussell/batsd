require 'spec_helper'

describe RecommendationList do
  context '#recommendation_reject' do
    before :each do
      @device = Factory(:device)
      @options = {
        :device => @device,
        :device_type => 'iphone',
      }
      RecommendationList.stub(:for_device).and_return([])
      RecommendationList.stub(:for_app).and_return([])
      RecommendationList.stub(:most_popular).and_return([])
    end

    context 'when store id is blank' do
      it 'returns true' do
        offer = Factory(:app).primary_offer
        offer.stub(:store_id_for_feed).and_return(nil)
        RecommendationList.new(@options).send(:recommendation_reject?, :offer => offer).should be_true
      end
    end
  end
end
