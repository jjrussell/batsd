require 'spec/spec_helper'

describe Tools::AppReviewsController do
  before :each do
    fake_the_web
    activate_authlogic
    admin = Factory(:admin)
    partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
    admin.partners << partner
    login_as(admin)

    @app = Factory(:app, :thumb_up_count => 0, :thumb_down_count => 0)
    @app2 = Factory(:app, :thumb_up_count => 0, :thumb_down_count => 0)
    @gamer = Factory(:gamer)
    gamer2 = Factory(:gamer)

    @gamer_review = Factory(:gamer_review, :author => @gamer, :app => @app)
    Factory(:gamer_review, :author => @gamer, :app => @app2, :user_rating => 0)
    Factory(:gamer_review, :author => gamer2, :app => @app, :user_rating => 0)
    Factory(:gamer_review, :author => gamer2, :app => @app2, :user_rating => 0)
  end

  describe '#index' do
    context 'when no params' do
      before :each do
        get 'index'
      end

      it 'returns all app reviews' do
        assigns[:app_reviews].size.should == 4
      end
    end

    context 'when has author_id and author_type as param' do
      before :each do
        get 'index', :author_id => @gamer.id, :author_type => 'Gamer'
      end

      it 'returns app reviews written by the author' do
        assigns[:app_reviews].scoped(:order => 'created_at').should == @gamer.app_reviews.scoped(:order => 'created_at')
      end
    end

    context 'when has app_id as param' do
      before :each do
        get 'index', :app_id => @app.id
      end

      it 'returns app reviews for app' do
        assigns[:app_reviews].scoped(:order => 'created_at').should == @app.app_reviews.scoped(:order => 'created_at')
      end
    end
  end

  describe '#create' do
    before :each do
      @employee = Factory(:employee)
      @options = {
        :app_review => {
          :author_id   => @employee.id,
          :author_type => 'Employee',
          :app_id      => @app2.id,
          :text        => "Sampe review",
          :user_rating => 1
        }
      }
      post 'create', @options
    end

    context 'when app review not exist' do
      it 'creates a app review' do
        flash[:notice].should == 'App review was successfully created.'
        response.should redirect_to(tools_app_reviews_path(:app_id => @app2.id))
      end

      it 'copies platform' do
        assigns[:app_review].platform.should == @app2.platform
      end

      it 'sets user_rating' do
        assigns[:app_review].user_rating.should == 1
      end

      it 'increases app thumb_up_count' do
        @app2.reload
        @app2.thumb_up_count.should == 1
      end

      it 'does not change app thumb_down_count' do
        @app2.reload
        @app2.thumb_down_count.should == 0
      end
    end

    context 'when the review already exist' do
      before :each do
        post 'create', @options
      end

      it 'sets a flash notice message' do
        response.session[:flash][:error].should == 'You have already reviewed this app.'
      end

      it 'renders tools/app_reviews/new' do
        response.should render_template('tools/app_reviews/new')
      end
    end
  end

  describe '#edit' do
    before :each do
      get 'edit', :id => @gamer_review.id
    end

    context 'when edit success' do
      it 'gets the app_review' do
        assigns[:app_review].should == @gamer_review
      end
    end
  end

  describe '#update' do
    before :each do
      @options = {
        :id => @gamer_review.id,
        :app_review => {
          :user_rating => -1
        }
      }
      put 'update', @options
    end

    context 'when update success' do
      it 'updates the user_rating of app_review' do
        assigns[:app_review].user_rating.should == -1
      end

      it 'sets a notice' do
        flash[:notice].should == 'App review was successfully updated.'
      end

      it "redirects to tools/aoo_reviews/index?app_id=" do
        response.should redirect_to(tools_app_reviews_path(:app_id => @gamer_review.app_id))
      end

      it 'updates app thumb_up_count' do
        @app.reload.thumb_up_count.should == 0
      end

      it 'updates app thumb_down_count' do
        @app.reload.thumb_down_count.should == 1
      end
    end
  end

  describe '#destroy' do
    before :each do
      delete 'destroy', :id => @gamer_review.id
      @app.reload
    end

    context 'when success delete' do
      it 'redirects to tools/app_reviews/index' do
        response.should redirect_to(tools_app_reviews_path)
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
