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

      Device.stubs(:new)
      Downloader.stubs(:get_with_retry)
      @mock_click = mock()
      @mock_click.stubs(:installed_at?).returns(true)
      @mock_click.stubs(:currency_id).returns(5)
      Click.expects(:find).with('5', :consistent => true).returns(@mock_click)
      Currency.stubs(:find_in_cache).with(5).returns('fake currency')
    end

    it 'renders error for invalid currency' do
      Currency.expects(:find_in_cache).with(5).returns(nil)
      post(:create, :click_key => '5')
      response.body.should == 'record not found'
    end

    it 'renders survey_complete' do
      post(:create, :click_key => '5')
      response.should render_template('survey_complete')
    end

    it 'does not reward if click is already complete' do
      Offer.expects(:find_in_cache).never
      post(:create, :click_key => '5')
    end

    it "renders new if all questions aren't answered" do
      @mock_click.expects(:installed_at?).returns(false)
      post(:create, :click_key => '5', :id => @offer.id)
      assigns(:missing_params).should be_true
      response.should render_template('new')
    end

    it 'saves a SurveyResult' do
      stub_device

      controller.expects(:get_geoip_data).returns('geoip data')
      @mock_click.expects(:installed_at?).returns(false)
      mock_result = mock()

      SurveyResult.expects(:new).returns(mock_result)
      mock_result.expects(:udid=).with(@udid)
      mock_result.expects(:click_key=).with('5')
      mock_result.expects(:geoip_data=).with('geoip data')
      mock_result.expects(:answers=).with({ @survey_question.text => 'a' })
      mock_result.expects(:save)

      post(:create, @request_params)
    end

    it 'saves the results to the device' do
      stub_survey_result

      controller.expects(:get_geoip_data).returns('geoip data')
      @mock_click.expects(:installed_at?).returns(false)
      mock_device = mock()

      Device.expects(:new).with(:key => @udid).returns(mock_device)
      previous_answers = {'where are you from?' => 'the moon'}
      expected_answers = previous_answers.merge(@survey_question.text => 'a')
      mock_device.expects(:survey_answers).returns(previous_answers)
      mock_device.expects(:survey_answers=).with(expected_answers)
      mock_device.expects(:save)

      post(:create, @request_params)
    end

    it 'calls downloader with the correct url' do
      stub_survey_result
      stub_device

      controller.expects(:get_geoip_data).returns('geoip data')
      @mock_click.expects(:installed_at?).returns(false)

      url = "#{API_URL}/offer_completed?click_key=5"
      Downloader.expects(:get_with_retry).with(url)
      post(:create, @request_params)
    end
  end
end
