require 'spec/spec_helper'

describe Tools::SurveyOffersController do
  integrate_views

  before :each do
    fake_the_web
    flash.stubs(:sweep)
    activate_authlogic
    user = Factory(:admin)
    partner = Factory(:partner, :id => TAPJOY_PARTNER_ID, :users => [user])
    @survey_question = Factory(:survey_question)
    @survey_offer = @survey_question.survey_offer
    login_as(user)
  end

  describe "index" do
    it "should return only visible survey offers" do
      get 'index'
      assigns(:survey_offers).should == [@survey_offer]
      @survey_offer.hide!
      get 'index'
      assigns(:survey_offers).should == []
    end
  end

  describe "new" do
    it "should assign a new survey offer" do
      get 'new'
      assigns(:survey_offer).should_not be_nil
      assigns(:survey_offer).bid.should == 0
    end

    it "should build blank questions" do
      get 'new'
      assigns(:survey_offer).survey_questions.size.should == 4
    end
  end

  describe "create" do
    it "should redirect on success" do
      survey_offer_attributes = {
        :name => 'quick survey',
        :bid  => '$7.00',
      }
      post 'create', :survey_offer => survey_offer_attributes
      flash[:notice].should == 'Survey offer created successfully'
      response.should be_redirect
      assigns(:survey_offer).bid.should == 700
    end

    it "should render an error on failure" do
      survey_offer_attributes = {
        :bid  => '$0.00',
      }
      post 'create', :survey_offer => survey_offer_attributes
      flash.now[:error].should == 'Problems creating survey offer'
      response.should render_template('new')
      assigns(:survey_offer).survey_questions.size.should == 4
    end

    it "should create the correct number of survey questions" do
      survey_offer_attributes = {
        :name => 'quick survey',
        :bid  => '$0.00',
        :survey_questions_attributes => {
          1 => {
            'text' => 'blah',
            'format' => 'select',
            'possible_responses' => 'a;b;c',
          }
        }
      }
      post 'create', :survey_offer => survey_offer_attributes
      flash[:notice].should == 'Survey offer created successfully'
      survey_offer = assigns(:survey_offer)
      survey_offer.survey_questions.count.should == 1

      survey_question = survey_offer.survey_questions.first
      survey_question.text.should == 'blah'
      survey_question.format.should == 'select'
      survey_question.possible_responses.should == %w( a b c )
    end
  end

  describe "edit" do
    it "should build blank questions" do
      get 'edit', :id => @survey_offer.id
      assigns(:survey_offer).survey_questions.size.should == 4
    end
  end

  describe "update" do
    it "should add new questions" do
      survey_offer_attributes = {
        :name => @survey_offer.name,
        :bid  => '$7.00',
        :survey_questions_attributes => {
          1 => {
            :id => @survey_question.id,
            'text' => @survey_question.text,
            'format' => @survey_question.format,
            'possible_responses' => @survey_question.possible_responses.join(';'),
          },
          2 => {
            'text' => 'blah',
            'format' => 'select',
            'possible_responses' => 'a;b;c',
          },
        },
      }
      put 'update',
        :id => @survey_offer.id,
        :survey_offer => survey_offer_attributes
      flash[:notice].should == 'Survey offer updated successfully'
      response.should be_redirect
      assigns(:survey_offer).survey_questions.count.should == 2
      assigns(:survey_offer).bid.should == 700
      @survey_offer.reload.survey_questions.count.should == 2
    end

    it "should remove questions" do
      survey_offer_attributes = {
        :name => @survey_offer.name,
        :bid  => '$0.00',
        :survey_questions_attributes => {
          1 => {
            :id => @survey_question.id,
            'text' => '',
            'format' => @survey_question.format,
            'possible_responses' => @survey_question.possible_responses.join(';'),
          },
        },
      }

      put 'update',
        :id => @survey_offer.id,
        :survey_offer => survey_offer_attributes

      flash[:notice].should == 'Survey offer updated successfully'
      response.should be_redirect

      assigns(:survey_offer).survey_questions.count.should == 0
      @survey_offer.reload.survey_questions.count.should == 0
    end

    it "should render an error" do
      survey_offer_attributes = {
        :name => '',
        :bid  => '$0.00',
      }
      put 'update',
        :id => @survey_offer.id,
        :survey_offer => survey_offer_attributes
      flash.now[:error].should == 'Problems updating survey offer'
      response.should render_template('edit')
    end
  end

  describe "destroy" do
    it "should hide the survey offer" do
      get 'destroy', :id => @survey_offer.id

      @survey_offer.reload.hidden.should == true
      flash[:notice].should == 'Survey offer removed successfully'
      response.should be_redirect
    end
  end
end
