require 'spec_helper'

describe VideosController do
  render_views

  before(:each) do
    OfferCacher.stub(:get_offer_list).and_return([])
    @currency = Factory(:currency)
    @params = {
      :udid => 'stuff',
      :publisher_user_id => 'more_stuff',
      :currency_id => @currency.id,
      :app_id => @currency.app.id
    }
  end

  describe '#index' do
    it 'returns an XML list' do
      get(:index, @params)

      response.content_type.should == 'application/xml'
    end
  end

  describe '#complete' do
    before(:each) do
      @offer = Factory(:video_offer)
    end

    it 'renders the completion screen' do
      get(:complete, @params.merge(:id => @offer.id, :offer_id => @offer.id))

      response.content_type.should == 'text/html'
    end
  end
end
