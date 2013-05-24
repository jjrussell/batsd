require 'spec_helper'

describe Dashboard::Tools::SurveyOffersController do
  render_views

  let(:admin)           { FactoryGirl.create(:admin) }
  let(:partner)         { FactoryGirl.create(:partner, :id => TAPJOY_SURVEY_PARTNER_ID, :users => [admin]) }
  let(:survey_offer)    { FactoryGirl.create(:survey_offer, :partner => partner) }
  let!(:survey_question) do
    q = FactoryGirl.create(:survey_question, :survey_offer => survey_offer)
    survey_offer.save
    q
  end
  let(:offer)           { survey_offer.primary_offer }

  before :each do
    flash.stub(:sweep)
    activate_authlogic
    login_as(admin)
  end

  describe '#index' do
    it 'displays visible offers' do
      get(:index)
      assigns(:survey_offers).should include survey_offer
    end

    it 'does not display hidden offers' do
      survey_offer.hide!
      get(:index)
      assigns(:survey_offers).should_not include survey_offer
    end
  end

  describe '#new' do
    it 'assigns a new survey offer' do
      get(:new)
      assigns(:survey_offer).should be_present
      assigns(:survey_offer).bid.should == 0
    end
  end

  describe '#create' do
    it 'redirects on success' do
      # pending "iOS SDK updates automatically populate flash[:notice]"
      survey_offer_attributes = {
        :name => 'quick survey',
        :bid  => '$7.00',
      }
      post(:create, :survey_offer => survey_offer_attributes)
      flash[:notice].should == 'Survey offer created successfully'
      response.should be_redirect
      assigns(:survey_offer).bid.should == 700
    end

    it 'renders an error on failure' do
      survey_offer_attributes = {
        :bid  => '$0.00'
      }
      post(:create, :survey_offer => survey_offer_attributes)
      flash.now[:error].should == 'Problems creating survey offer'
    end

    it 'creates the correct number of survey questions' do
      # pending "iOS SDK updates automatically populate flash[:notice]"
      survey_offer_attributes = {
        :name => 'quick survey',
        :bid  => '$0.00',
        :questions_attributes => {
          1 => {
            'text' => 'blah',
            'format' => 'select',
            'possible_responses' => 'a;b;c',
          }
        }
      }
      post(:create, :survey_offer => survey_offer_attributes)
      flash[:notice].should == 'Survey offer created successfully'
      survey_offer = assigns(:survey_offer)
      survey_offer.survey_questions.count.should == 1

      survey_offer.reload
      survey_question = survey_offer.questions.first
      survey_question.text.should == 'blah'
      survey_question.format.should == 'select'
      survey_question.responses.should == %w( a b c )
    end
  end

  describe '#update' do
    it 'adds new questions' do
      survey_offer_attributes = {
        :name => survey_offer.name,
        :bid  => '$7.00',
        :questions_attributes => {
          1 => {
            'text' => survey_question.text,
            'format' => survey_question.format,
            'possible_responses' => survey_question.responses.join(';')
          },
          2 => {
            'text' => 'blah',
            'format' => 'select',
            'possible_responses' => 'a;b;c'
          }
        }
      }

      put(:update,
        :id => survey_offer.id,
        :survey_offer => survey_offer_attributes
      )

      survey_offer.questions.count.should == 2
    end

    it 'removes questions' do
      survey_offer_attributes = {
        :name => survey_offer.name,
        :bid  => '$0.00',
        :questions_attributes => {
          1 => {
            :id => survey_question.id,
            'text' => '',
            'format' => survey_question.format,
            'responses' => survey_question.possible_responses
          },
        },
      }

      put(:update,
        :id => survey_offer.id,
        :survey_offer => survey_offer_attributes
      )

      flash[:notice].should == 'Survey offer updated successfully'
      response.should be_redirect

      assigns(:survey_offer).survey_questions.count.should == 0
      survey_offer.reload.survey_questions.count.should == 0
    end

    it 'renders an error' do
      survey_offer_attributes = {
        :name => '',
        :bid  => '$0.00',
      }
      put(:update,
        :id => survey_offer.id,
        :survey_offer => survey_offer_attributes
      )
      flash.now[:error].should == 'Problems updating survey offer'
      response.should render_template('edit')
    end
  end

  describe '#destroy' do
    before(:each) do
      get(:destroy, :id => survey_offer.id)
    end

    it 'hides the survey offer' do
      survey_offer.reload
      survey_offer.should be_hidden
    end

    it 'redirects to the survey offer index page' do
      response.should be_redirect
    end

    it 'gives notice that the survey was removed' do
      flash[:notice].should == 'Survey offer removed successfully'
    end
  end

  describe '#toggle_enabled' do
    context 'given an enabled survey' do
      it 'disables the survey' do
        # hard to fake the primary_offer being enabled
        SurveyOffer.stub(:find).with(survey_offer.id).and_return(survey_offer)
        SurveyOffer.stub(:find).with(survey_offer.id, :include => nil, :select => nil).and_return(survey_offer)
        survey_offer.stub(:enabled?).and_return(true)
        survey_offer.should_receive(:disable!)
        get(:toggle_enabled, :id => survey_offer.id)
      end
    end

    context 'given an disabled survey' do
      # The default for a new survey_offer

      it 'enables the survey' do
        SurveyOffer.stub(:find).with(survey_offer.id).and_return(survey_offer)
        SurveyOffer.stub(:find).with(survey_offer.id, :include => nil, :select => nil).and_return(survey_offer)
        survey_offer.stub(:enabled?).and_return(false)
        survey_offer.should_receive(:enable!)
        get(:toggle_enabled, :id => survey_offer.id)
      end
    end
  end
end
