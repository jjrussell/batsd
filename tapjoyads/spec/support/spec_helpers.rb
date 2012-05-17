module SpecHelpers
  def login_as(user)
    UserSession.create(user)
  end

  def games_login_as(user)
    GamerSession.create(user)
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
