require 'spec_helper'

describe VideosController do
  render_views

  before(:each) do
    OfferCacher.stub(:get_offer_list).and_return([])
    @currency = FactoryGirl.create(:currency)
    @params = {
      :udid => 'stuff',
      :publisher_user_id => 'more_stuff',
      :currency_id => @currency.id,
      :app_id => @currency.app.id,
      :connection_type => 'wifi'
    }

    @app = @currency.app
    App.stub(:find_in_cache).with(@app.id).and_return(@app)
  end

  describe '#index' do
    it 'returns an XML list' do
      get(:index, @params)

      response.content_type.should == 'application/xml'
    end

    it 'should access the offer_list' do
      @app.stub(:videos_cache_on? => true)
      offer_list = mock(:get_offers => [[]])
      controller.should_receive(:offer_list).and_return(offer_list)
      get(:index, @params)
    end

    context 'when the accessing SDK supports video cache controls' do
      before(:each) do
        controller.stub(:library_version => mock(:control_video_caching? => true))
      end

      context 'when the publisher app has disabled caching' do
        before :each do
          @app.stub(:videos_cache_on? => false)
        end

        it 'should not access the offer_list' do
          controller.should_not_receive(:offer_list)
          get(:index, @params)
        end
      end

      context 'when hide_videos is true' do
        before :each do
          @params[:hide_videos] = 'true'
        end

        it 'should not access the offer_list' do
          controller.should_not_receive(:offer_list)
          get(:index, @params)
        end
      end
    end
  end

  describe '#complete' do
    before(:each) do
      @offer = FactoryGirl.create(:video_offer)
    end

    it 'renders the completion screen' do
      get(:complete, @params.merge(:id => @offer.id, :offer_id => @offer.id))

      response.content_type.should == 'text/html'
    end
  end
end
