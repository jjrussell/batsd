require 'spec/spec_helper'

describe Tools::GamerReviewsController do
  before :each do
    fake_the_web
    activate_authlogic
    @admin = Factory(:admin)
    @partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
    @admin.partners << @partner
    login_as(@admin)

    @app = Factory(:app)
    @app2 = Factory(:app)
    @gamer = Factory(:gamer)
    @gamer2 = Factory(:gamer)

    @gamer_review11 = Factory(:gamer_review, :author => @gamer, :app => @app)
    @gamer_review12 = Factory(:gamer_review, :author => @gamer, :app => @app2)
    @gamer_review21 = Factory(:gamer_review, :author => @gamer2, :app => @app)
    @gamer_review22 = Factory(:gamer_review, :author => @gamer2, :app => @app2)
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
        assigns[:gamer_reviews].size.should == 2
      end
    end

    context 'when has app_id as param' do
      before :each do
        get 'index', :app_id => @app.id
      end

      it 'returns gamer reviews for app' do
        assigns[:gamer_reviews].size.should == 2
      end
    end
  end
  
  describe '#update' do
    before :each do
      @gamer_review11.update_app_rating_counts(0)
      @options = {
        :id => @gamer_review11.id,
        :gamer_review => {
          :user_rating => -1
        }
      }
      put 'update', @options
    end

    context 'when update success' do
      it 'updates gamer review' do
        assigns[:gamer_review].user_rating.should == -1
        flash[:notice].should == 'App review was successfully updated.'
        response.should redirect_to(tools_gamer_reviews_path(:app_id => @gamer_review11.app_id))
      end
      
      it 'updates app thumb_up_count' do
        assigns[:gamer_review].app.thumb_up_count.should == 0
      end
      
      it 'updates app thumb_down_count' do
        assigns[:gamer_review].app.thumb_down_count.should == 1
      end
    end
  end
  
end
