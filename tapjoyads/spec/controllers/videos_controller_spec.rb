require 'spec_helper'

describe VideosController do
  integrate_views

  before(:all) do
    fake_the_web
    OfferCacher.stubs(:get_offer_list).returns([])
  end

  before(:each) do
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
      get :index, @params

      response.content_type.should == 'application/xml'
    end
  end

  describe '#complete' do
    before(:each) do
      @offer = Factory(:video_offer)
    end

    it 'renders the completion screen' do
      get :complete, @params.merge(:id => @offer.id, :offer_id => @offer.id)

      response.content_type.should == 'text/html'
    end
  end
end
