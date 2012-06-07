require 'spec/spec_helper'

describe Games::ConfirmationsController do
  before :each do
    fake_the_web
    activate_authlogic
  end

  describe '#create' do
    before :each do
      @gamer = Factory(:gamer)
    end
    context 'with valid data' do
      it 'redirects to url with tracking params' do
        data = ObjectEncryptor.encrypt({:token => @gamer.confirmation_token, :content => 'test_campaign'})
        get(:create, :data => data)
        response.code.should == "302"
        request.session[:flash][:notice].should == 'Email address confirmed.'
        response.redirect_url.should == games_root_url(:utm_campaign => 'welcome_email',
                             :utm_medium   => 'email',
                             :utm_source   => 'tapjoy',
                             :utm_content  => 'test_campaign',
                             :data         => data)
      end
    end
    context 'with valid data for confirm only message' do
      it 'queues post confirm message' do
        Sqs.should_receive(:send_message)
        data = ObjectEncryptor.encrypt({:token => @gamer.confirmation_token, :content => 'confirm_only'})
        get(:create, :data => data)
      end
    end
    context 'with valid token only' do
      it 'redirects to url without tracking params' do
        get(:create, :token => @gamer.confirmation_token)
        response.code.should == "302"
        request.session[:flash][:notice].should == 'Email address confirmed.'
        response.redirect_url.should == games_root_url
      end
    end
    context 'with invalid token' do
      it 'redirects with flash error' do
        get(:create, :token => 'bad_token')
        response.code.should == "302"
        request.session[:flash][:error].should == 'Unable to confirm email address.'
        response.redirect_url.should == games_root_url
      end
    end
    context 'with extra spaces in the posted data (like SendGrid, sometimes)' do
      it 'strips the spaces and continues' do
        Sqs.should_receive(:send_message)
        data = ObjectEncryptor.encrypt({:token => @gamer.confirmation_token, :content => 'confirm_only'}).insert(5, ' ')
        get(:create, :data => data)
      end
    end
  end
end
