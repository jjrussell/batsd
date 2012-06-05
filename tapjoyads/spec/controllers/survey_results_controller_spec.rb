require 'spec/spec_helper'

describe SurveyResultsController do
  before :each do
    fake_the_web
    user = Factory(:admin)
    partner = Factory(:partner, :id => TAPJOY_PARTNER_ID, :users => [user])
    survey_offer = Factory(:survey_offer)
    @survey_question = Factory(:survey_question, :survey_offer => survey_offer)
    survey_offer.save
    @offer = survey_offer.primary_offer
  end

  describe '#new' do
    it 'verifies params' do
      get(:new)
      response.body.should == 'missing required params'
    end

    it 'assigns survey questions' do
      get(:new, :udid => 'something', :click_key => '5', :id => @offer.id)
      assigns(:survey_questions).length.should == 1
      response.should render_template('new')
    end
  end

  describe '#create' do
    before :each do
      @udid = UUIDTools::UUID.random_create.to_s
      @request_params = {
        :click_key          => '5',
        :id                 => @offer.id,
        :udid               => @udid,
        @survey_question.id => 'a',
      }

      Device.stub(:new)
      Downloader.stub(:get_with_retry)
      @mock_click = mock()
      @mock_click.stub(:installed_at?).and_return(true)
      @mock_click.stub(:currency_id).and_return(5)
      Click.should_receive(:find).with('5', :consistent => true).and_return(@mock_click)
      Currency.stub(:find_in_cache).with(5).and_return('fake currency')
    end

    it 'renders error for invalid currency' do
      Currency.should_receive(:find_in_cache).with(5).and_return(nil)
      post(:create, :click_key => '5')
      response.body.should == 'record not found'
    end

    it 'renders survey_complete' do
      post(:create, :click_key => '5')
      response.should render_template('survey_complete')
    end

    it 'does not reward if click is already complete' do
      Offer.should_receive(:find_in_cache).never
      post(:create, :click_key => '5')
    end

    it "renders new if all questions aren't answered" do
      @mock_click.should_receive(:installed_at?).and_return(false)
      post(:create, :click_key => '5', :id => @offer.id)
      assigns(:missing_params).should be_true
      response.should render_template('new')
    end

  end
end
