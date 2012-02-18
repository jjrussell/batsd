require 'spec/spec_helper'

describe Games::AppReviewsController do
  before :each do
    fake_the_web
    activate_authlogic
    @gamer = Factory(:gamer)
    login_as(@gamer)
    @app = Factory(:app, :thumb_up_count => 0, :thumb_down_count => 0)
  end

  describe '#index' do
    before :each do
      @gamer2 = Factory(:gamer)
      app2 = Factory(:app, :thumb_up_count => 0, :thumb_down_count => 0)
      Factory(:gamer_review, :author => @gamer, :app => @app)
      Factory(:gamer_review, :author => @gamer, :app => app2)
      Factory(:gamer_review, :author => @gamer2, :app => @app)
    end

    context 'when not params' do
      before :each do
        get :index
      end

      it "returns current gamer's reviews" do
        assigns[:app_reviews].scoped(:order => 'created_at').should == @gamer.app_reviews.scoped(:order => 'created_at')
      end
    end

    context 'when has app_id as params' do
      before :each do
        get(:index, :app_id => @app.id)
      end

      it 'returns all the reviews of the app' do
        assigns[:app_reviews].should == @app.app_reviews.scoped(:order => 'created_at')
      end
    end

    context 'when has gamer_id as params' do
      before :each do
        get(:index, :gamer_id => @gamer2.id)
      end

      it 'returns all the reviews written by the gamer' do
        assigns[:app_reviews].scoped(:order => 'created_at').should == @gamer2.app_reviews.scoped(:order => 'created_at')
      end
    end
  end

  describe '#create' do
    before :each do
      @options = {
        :app_review => {
          :author_id   => @gamer.id,
          :author_type => 'Gamer',
          :app_id      => @app.id,
          :text        => "Sampe review",
          :user_rating => 1
        }
      }
      post(:create, @options)
    end

    context 'when app review not exist' do
      it 'creates a app review' do
        flash[:notice].should == 'App review was successfully created.'
        response.should redirect_to(games_app_reviews_path(:app_id => @app.id))
      end

      it 'copies platform' do
        assigns[:app_review].platform.should == @app.platform
      end

      it 'sets user_rating' do
        assigns[:app_review].user_rating.should == 1
      end

      it 'increases app thumb_up_count' do
        @app.reload
        @app.thumb_up_count.should == 1
      end

      it 'does not change app thumb_down_count' do
        @app.reload
        @app.thumb_down_count.should == 0
      end
    end

    context 'when the review already exist' do
      before :each do
        post(:create, @options)
      end

      it 'sets a flash notice message' do
        response.session[:flash][:notice].should == 'You have already reviewed this app.'
      end

      it 'renders games/app_reviews/index' do
        response.should render_template('games/app_reviews/index')
      end
    end
  end

  describe '#edit' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer, :app => @app)

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
      @gamer_review = Factory(:gamer_review, :author => @gamer, :app => @app)

      @options = {
        :id => @gamer_review.id,
        :app_review => {
          :user_rating => -1
        }
      }
      put(:update, @options)
    end

    context 'when update success' do
      it 'updates the user_rating of app_review' do
        assigns[:app_review].user_rating.should == -1
      end

      it 'sets a notice' do
        flash[:notice].should == 'App review was successfully updated.'
      end

      it "redirects to games/app_reviews/index" do
        response.should redirect_to(games_app_reviews_path)
      end

      it 'updates app thumb_up_count' do
        assigns[:app_review].app.thumb_up_count.should == 0
      end

      it 'updates app thumb_down_count' do
        assigns[:app_review].app.thumb_down_count.should == 1
      end
    end
  end

  describe '#destroy' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer)
      delete(:destroy, :id => @gamer_review.id)
      @app.reload
    end

    context 'when success delete' do
      it 'redirects to games/app_reviews/index' do
        response.should redirect_to(games_app_reviews_path)
      end

      it 'resets app thumb_up_count' do
        @app.thumb_up_count.should == 0
      end

      it 'resets app thumb_down_count' do
        @app.thumb_down_count.should == 0
      end
    end
  end
end
