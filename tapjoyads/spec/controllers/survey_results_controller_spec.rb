require 'spec_helper'

describe SurveyResultsController do
  let(:admin)           { FactoryGirl.create(:admin) }
  let(:partner)         { FactoryGirl.create(:partner, :id => TAPJOY_SURVEY_PARTNER_ID, :users => [admin]) }
  let(:survey_offer)    { FactoryGirl.create(:survey_offer, :partner => partner) }
  let!(:survey_question) do
    q = FactoryGirl.create(:survey_question, :survey_offer => survey_offer)
    survey_offer.save
    q
  end
  let(:offer)           { survey_offer.primary_offer }

  describe '#new' do
    it 'verifies params' do
      get(:new)
      response.body.should =~ /missing parameters/
    end

    it 'assigns survey questions' do
      SurveyOffer.stub(:find_in_cache).and_return(survey_offer)
      get(:new, :udid => 'something', :click_key => '5', :id => offer.id)
      assigns(:survey_questions).length.should == 1
      response.should render_template('new')
    end
  end

  describe '#create' do
    let(:udid)    { FactoryGirl.generate(:guid) }
    let(:mock_click) do
      mock('Mock Click', :installed_at? => true, :currency_id => 5)
    end

    before :each do
      Device.stub(:new)
      Downloader.stub(:get_with_retry)
      Click.stub(:find).with('5', :consistent => true).and_return(mock_click)
      Currency.stub(:find_in_cache).with(5).and_return('fake currency')
      SurveyOffer.stub(:find_in_cache).and_return(survey_offer)
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
      mock_click.stub(:installed_at?).and_return(false)

      post(:create, :click_key => '5', :id => offer.id)
      assigns(:missing_params).should be_true
      response.should render_template('new')
    end

  end
end
