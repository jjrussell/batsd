require 'spec/spec_helper'

describe Games::AppReviews::FlagModerationController do
  before :each do
    fake_the_web
    activate_authlogic
    @gamer = Factory(:gamer)
    @other_gamer = Factory(:gamer)
    controller.stubs(:current_gamer).returns(@gamer)
    app = Factory(:app)
    @app_metadata = app.app_metadatas.first
    @troll_review = Factory(:gamer_review, :author => Factory(:gamer), :user_rating => 0)
    @good_review = Factory(:gamer_review, :author => Factory(:gamer), :user_rating => 0)
    @user_owned_review = Factory(:gamer_review, :author => @gamer, :user_rating => 0)
  end

  context 'when flagging a message as inappropriate' do
    it 'flags a bad review' do
      post(:create, { :app_review_id => @troll_review.id })
      @gamer.reload
      @troll_review.reload
      @troll_review.bury_votes.count.should == 1
      @troll_review.author.been_buried_count.should == 1
      @troll_review.bury_votes.size.should == 1
      @troll_review.helpful_votes.count.should == 0
      should respond_with_content_type :json
      should respond_with(201)
    end
    it 'refuses to flag a review the same way twice, but returns 200 ' do
      post(:create, { :app_review_id => @troll_review.id, :vote => 'flag' })
      post(:create, { :app_review_id => @troll_review.id, :vote => 'flag' })
      should respond_with_content_type :json
      should respond_with(200)
    end
    it 'lets you flag and fave a review' do
      @gamer.helpful_review_votes.build({ :app_review_id => @troll_review.id, :value => 1 })
      post(:create, { :app_review_id => @troll_review.id, :vote => 'flag' })
      should respond_with_content_type :json
      should respond_with(201)
    end
    it 'refuses to flag a review self-owned review' do
      post(:create, { :app_review_id => @user_owned_review.id, :vote => 'flag' })
      @troll_review.helpful_votes.count.should == 0
      @troll_review.bury_votes.count.should == 0
      should respond_with_content_type :json
      should respond_with(403)
    end
    it 'un-does an errant flag' do
      post(:create, { :app_review_id => @troll_review.id, :vote => 'flag' })
      delete(:destroy, { :app_review_id => @troll_review.id, :vote => 'flag' })
      @troll_review.reload
      @troll_review.bury_votes.count.should == 0
      @troll_review.author.been_buried_count.should == 0
      should respond_with_content_type :json
      should respond_with(200)
    end
    it "refuses to undo flag that doesn't exist" do
      post(:create, { :app_review_id => @troll_review.id, :vote => 'flag' })
      delete(:destroy, { :app_review_id => @good_review.id, :vote => 'flag' })
      should respond_with_content_type :json
      should respond_with(404)
    end
    it "refuses to undo a flag that the user doesn't own'" do
      post(:create, { :app_review_id => @troll_review.id, :vote => 'flag' })
      controller.stubs(:current_gamer).returns(@other_gamer)
      delete(:destroy, { :app_review_id => @troll_review.id, :vote => 'flag' })
      should respond_with_content_type :json
      should respond_with(404)
    end
  end
end

describe Games::AppReviews::FaveModerationController do
  before :each do
    fake_the_web
    activate_authlogic
    @gamer = Factory(:gamer)
    @other_gamer = Factory(:gamer)
    controller.stubs(:current_gamer).returns(@gamer)
    app = Factory(:app)
    @app_metadata = app.app_metadatas.first
    @troll_review = Factory(:gamer_review, :author => Factory(:gamer), :user_rating => 0)
    @good_review = Factory(:gamer_review, :author => Factory(:gamer), :user_rating => 0)
    @user_owned_review = Factory(:gamer_review, :author => @gamer, :user_rating => 0)
  end
  context 'when upvoting a message' do
    it 'upvotes a good review' do
      post(:create, { :app_review_id => @good_review.id, :value => 1 })
      @good_review.reload
      @good_review.author.been_helpful_count.should == 1
      @good_review.bury_votes.count.should == 0
      @good_review.helpful_votes.count.should == 1
      @good_review.reload
      @good_review.helpful_values_sum.should == 1
      should respond_with_content_type :json
      should respond_with(201)
    end

    it 'does not let you flag and fave a review' do
      @gamer.bury_review_votes.build({ :app_review_id => @troll_review.id }).save
      post(:create, { :app_review_id => @troll_review.id, :value => 1 })
      should respond_with_content_type :json
      should respond_with(403)
    end
  end
end
