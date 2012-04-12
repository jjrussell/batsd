module SpecHelpers
  def login_as(user)
    UserSession.create(user)
  end

  def games_login_as(user)
    GamerSession.create(user)
  end

  def stub_device
    mock_answers = {'Where are you from?' => 'the moon'}
    mock_device = mock()
    mock_device.stubs(:survey_answers).returns(mock_answers)
    mock_device.stubs(:survey_answers=)
    mock_device.stubs(:save)
    Device.stubs(:new).returns(mock_device)
  end

  def stub_survey_result
    mock_result = mock()
    mock_result.stubs(:udid=)
    mock_result.stubs(:click_key=)
    mock_result.stubs(:geoip_data=)
    mock_result.stubs(:answers=)
    mock_result.stubs(:save)
    SurveyResult.stubs(:new).returns(mock_result)
  end

  def should_respond_with_json_error(code)
    should respond_with(code)
    should respond_with_content_type(:json)
    result = JSON.parse(response.body)
    result['success'].should be_false
    result['error'].should be_present
  end

  def should_respond_with_json_success(code)
    should respond_with(code)
    should respond_with_content_type(:json)
    result = JSON.parse(response.body)
    result['success'].should be_true
    result['error'].should_not be_present
  end

  def fake_the_web
    Resolv.stubs(:getaddress).returns('1.1.1.1')
    RightAws::SdbInterface.stubs(:new).returns(FakeSdb.new)
    SimpledbResource.reset_connection
    AWS::S3.stubs(:new).returns(FakeS3.new)
  end
end
