require 'spec/spec_helper'

describe Games::GamerReviewsController do
  before :each do
    fake_the_web
    activate_authlogic
    @gamer = Factory(:gamer)
    login_as(@gamer)
    @app = Factory(:app, :thumb_up_count => 0, :thumb_down_count => 0)
  end

  describe '#create' do
    before :each do
      @options = {
        :gamer_review => {
          :author_id   => @gamer.id,
          :author_type => 'Gamer',
          :app_id      => @app.id,
          :text        => "Sampe review",
          :user_rating => 1
        }
      }
      post 'create', @options
    end

    context 'when gamer review not exist' do
      it 'creates a gamer review' do
        flash[:notice].should == 'App review was successfully created.'
        response.should redirect_to(new_games_gamer_review_path(:app_id => @app.id))
      end

      it 'copies platform' do
        assigns[:gamer_review].platform.should == @app.platform
      end

      it 'sets user_rating' do
        assigns[:gamer_review].user_rating.should == 1
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
        post 'create', @options
      end

      it 'sets a flash notice message' do
        response.session[:flash][:notice].should == 'You have already reviewed this app.'
      end

      it 'renders games/gamer_reviews/new' do
        response.should render_template('games/gamer_reviews/new')
      end
    end
  end

  describe '#edit' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer, :app => @app)

      get 'edit', :id => @gamer_review
    end

    context 'when edit success' do
      it 'gets the gamer_review' do
        assigns[:gamer_review].should == @gamer_review
      end
    end
  end

  describe '#update' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer, :app => @app)

      @options = {
        :id => @gamer_review.id,
        :gamer_review => {
          :user_rating => -1
        }
      }
      put 'update', @options
    end

    context 'when update success' do
      it 'updates the user_rating of gamer_review' do
        assigns[:gamer_review].user_rating.should == -1
      end

      it 'sets a notice' do
        flash[:notice].should == 'App review was successfully updated.'
      end

      it "redirects to games/gamer_reviews/index" do
        response.should redirect_to(games_gamer_reviews_path)
      end

      it 'updates app thumb_up_count' do
        assigns[:gamer_review].app.thumb_up_count.should == 0
      end

      it 'updates app thumb_down_count' do
        assigns[:gamer_review].app.thumb_down_count.should == 1
      end
    end
  end

  describe '#destroy' do
    before :each do
      @gamer_review = Factory(:gamer_review, :author => @gamer)
      delete 'destroy', :id => @gamer_review.id
      @app.reload
    end

    context 'when success delete' do
      it 'redirects to games/gamer_reviews/index' do
        response.should redirect_to(games_gamer_reviews_path)
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
