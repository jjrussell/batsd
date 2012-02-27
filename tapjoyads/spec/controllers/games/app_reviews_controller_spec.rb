require 'spec/spec_helper'

describe Games::AppReviewsController do
  before :each do
    activate_authlogic
    @gamer = Factory(:gamer)
    login_as(@gamer)
    @app_metadata = Factory(:app_metadata, :thumbs_up => 0, :thumbs_down => 0)
    Factory(:app_metadata_mapping, :app_metadata => @app_metadata)
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

<<<<<<< HEAD
      it 'returns all the reviews written by the gamer' do
        assigns[:app_reviews].scoped(:order => 'created_at').should == @gamer2.app_reviews.scoped(:order => 'created_at')
=======
      it 'returns all the reviews of the app' do
        assigns[:app_reviews].collect(&:id).sort.should == @app_metadata.app_reviews.collect(&:id).sort
>>>>>>> 9478c2cdb935285aa0db154f3be6b8dff179ccba
      end
    end
  end

  describe '#new' do
    before :each do
      @gamer2 = Factory(:gamer)
      app_metadata2 = Factory(:app_metadata, :thumbs_up => 0, :thumbs_down => 0)
      Factory(:gamer_review, :author => @gamer, :app_metadata => @app_metadata)
      Factory(:gamer_review, :author => @gamer, :app_metadata => app_metadata2)
      Factory(:gamer_review, :author => @gamer2, :app_metadata => @app_metadata)
    end
    context 'user has not reviewed the app' do
      before :each do
        get(:index, :app_metadata_id => @app_metadata.id)
      end

<<<<<<< HEAD
      it 'creates new app review' do
      end
    end

    context 'user has already reviewed the app' do
      it 'edits existing app review' do
=======
      it 'returns all the reviews written by the gamer' do
        assigns[:app_reviews].collect(&:id).sort.should == @gamer2.app_reviews.collect(&:id).sort
>>>>>>> 9478c2cdb935285aa0db154f3be6b8dff179ccba
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
          :user_rating     => 1
        }
      }
      post(:create, @options)
    end

    context 'when app review not exist' do
      it 'creates a app review' do
        flash[:notice].should == 'Successfully reviewed this app.'
        response.should redirect_to(games_app_reviews_path(:app_metadata_id => @app_metadata.id))
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

      it 'renders games/app_reviews/index' do
        response.should render_template('games/app_reviews/index')
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

      it 'updates app_metadata thumbs_up' do
        assigns[:app_review].app_metadata.thumbs_up.should == 0
      end

      it 'updates app_metadata thumbs_down' do
        assigns[:app_review].app_metadata.thumbs_down.should == 1
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
