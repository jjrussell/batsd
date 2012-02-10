require 'spec/spec_helper'

describe Tools::GamerReviewsController do
  before :each do
    fake_the_web
    activate_authlogic
    admin = Factory(:admin)
    partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
    admin.partners << partner
    login_as(admin)

    @app = Factory(:app, :thumb_up_count => 0, :thumb_down_count => 0)
    app2 = Factory(:app, :thumb_up_count => 0, :thumb_down_count => 0)
    @gamer = Factory(:gamer)
    gamer2 = Factory(:gamer)

    @gamer_review = Factory(:gamer_review, :author => @gamer, :app => @app)
    Factory(:gamer_review, :author => @gamer, :app => app2, :user_rating => 0)
    Factory(:gamer_review, :author => gamer2, :app => @app, :user_rating => 0)
    Factory(:gamer_review, :author => gamer2, :app => app2, :user_rating => 0)
  end

  describe '#index' do
    context 'when no params' do
      before :each do
        get 'index'
      end

      it 'returns all gamer reviews' do
        assigns[:gamer_reviews].size.should == 4
      end
    end

    context 'when has author_id as param' do
      before :each do
        get 'index', :author_id => @gamer.id
      end

      it 'returns gamer reviews written by the author' do
        assigns[:gamer_reviews].scoped(:order => 'created_at').should == @gamer.gamer_reviews.scoped(:order => 'created_at')
      end
    end

    context 'when has app_id as param' do
      before :each do
        get 'index', :app_id => @app.id
      end

      it 'returns gamer reviews for app' do
        assigns[:gamer_reviews].scoped(:order => 'created_at').should == @app.gamer_reviews.scoped(:order => 'created_at')
      end
    end
  end

  describe '#edit' do
    before :each do
      get 'edit', :id => @gamer_review.id
    end

    context 'when edit success' do
      it 'gets the gamer_review' do
        assigns[:gamer_review].should == @gamer_review
      end
    end
  end

  describe '#update' do
    before :each do
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

      it "redirects to tools/gamer_reviews/index?app_id=" do
        response.should redirect_to(tools_gamer_reviews_path(:app_id => @gamer_review.app_id))
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
      it 'redirects to tools/gamer_reviews/index' do
        response.should redirect_to(tools_gamer_reviews_path)
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
