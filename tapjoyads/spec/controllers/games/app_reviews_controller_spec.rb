require 'spec/spec_helper'

describe Games::AppReviewsController do
  before :each do
    fake_the_web
    activate_authlogic
    @gamer = Factory(:gamer)
    login_as(@gamer)
    app = Factory(:app)
    @currency = Factory(:currency, :app => app)
    @app_metadata = app.app_metadatas.first
  end

  describe '#index' do
    before :each do
      @gamer2 = Factory(:gamer)
      app_metadata2 = Factory(:app_metadata, :thumbs_up => 0, :thumbs_down => 0)
      Factory(:gamer_review, :author => @gamer, :app_metadata => @app_metadata)
      Factory(:gamer_review, :author => @gamer, :app_metadata => app_metadata2)
      Factory(:gamer_review, :author => @gamer2, :app_metadata => @app_metadata)
    end

    context 'when not params' do
      before :each do
        get :index
      end

      it "returns current gamer's reviews" do
        assigns[:app_reviews].collect(&:id).sort.should == @gamer.app_reviews.collect(&:id).sort
      end
    end

    context 'when has gamer_id as params' do
      before :each do
        get(:index, :gamer_id => @gamer2.id)
      end

      it 'returns all the reviews written by the gamer' do
        assigns[:app_reviews].collect(&:id).sort.should == @gamer2.app_reviews.collect(&:id).sort
      end
    end
  end

  describe '#create' do
    before :each do
      @options = {
        :app_review => {
          :author_id       => @gamer.id,
          :author_type     => 'Gamer',
          :app_metadata_id => @app_metadata.id,
          :text            => "Sampe review",
          :user_rating     => 1,
          :eid             => ObjectEncryptor.encrypt(@currency.id),
        }
      }
      post(:create, @options)
    end

    context 'when app review not exist' do
      it 'creates an app review' do
        flash[:notice].should == 'Successfully reviewed this app.'
      end

      it 'should redirect to earn' do
        response.should redirect_to games_earn_path(:eid => ObjectEncryptor.encrypt(@currency.id))
      end

      it 'sets user_rating' do
        assigns[:app_review].user_rating.should == 1
      end

      it 'increases app_metadata thumbs_up' do
        @app_metadata.reload
        @app_metadata.thumbs_up.should == 1
      end

      it 'does not change app_metadata thumbs_down' do
        @app_metadata.reload
        @app_metadata.thumbs_down.should == 0
      end
    end

    context 'when the review already exist' do
      before :each do
        post(:create, @options)
      end

      it 'sets a flash notice message' do
        response.session[:flash][:error].should == 'You have already reviewed this app.'
      end

      it 'redirects to earn' do
        response.should redirect_to games_earn_path(:eid => ObjectEncryptor.encrypt(@currency.id))
      end
    end
  end

  describe '#edit' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer, :app_metadata => @app_metadata)

      get(:edit, :id => @gamer_review)
    end

    context 'when edit success' do
      it 'gets the app_review' do
        assigns[:app_review].should == @gamer_review
      end
    end
  end

  describe '#update' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer, :app_metadata => @app_metadata)

      @options = {
        :id => @gamer_review.id,
        :app_review => {
          :eid => ObjectEncryptor.encrypt(@currency.id),
          :user_rating => -1,
        }
      }
    end

    context 'when update success' do
      before :each do
        put(:update, @options)
      end

      it 'updates the user_rating of app_review' do
        assigns[:app_review].user_rating.should == -1
      end

      it 'sets a notice' do
        flash[:notice].should == 'App review was successfully updated.'
      end

      it "redirects to games/app_reviews/index" do
        response.should redirect_to games_earn_path(:eid => ObjectEncryptor.encrypt(@currency.id))
      end

      it 'updates app_metadata thumbs_up' do
        assigns[:app_review].app_metadata.thumbs_up.should == 0
      end

      it 'updates app_metadata thumbs_down' do
        assigns[:app_review].app_metadata.thumbs_down.should == 1
      end
    end

    context 'trying to update unsafe attributes' do
      it 'should not update' do
        hax0r = Factory(:gamer)
        original_author_id = @gamer_review.author_id
        @options[:app_review][:author_id] = hax0r.id
        put(:update, @options)
        @gamer_review.reload
        @gamer_review.author_id.should == original_author_id
      end
    end
  end

  describe '#destroy' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer)
      delete(:destroy, :id => @gamer_review.id)
      @app_metadata.reload
    end

    context 'when success delete' do
      it 'redirects to games/app_reviews/index' do
        response.should redirect_to(games_app_reviews_path)
      end

      it 'resets app_metadata thumbs_up' do
        @app_metadata.thumbs_up.should == 0
      end

      it 'resets app_metadata thumbs_down' do
        @app_metadata.thumbs_down.should == 0
      end
    end
  end
end
