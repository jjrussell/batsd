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
    context 'with valid token and campaign' do
      it 'redirects to url with tracking params' do
        get(:create, :token => @gamer.confirmation_token, :content => 'test_campaign')
        response.code.should == "302"
        response.session[:flash][:notice].should == 'Email address confirmed.'
        response.redirected_to.should == games_root_path(:utm_campaign => 'email_confirm',
                             :utm_medium   => 'email',
                             :utm_source   => 'tapjoy',
                             :utm_content  => 'test_campaign')
      end
    end
    context 'with valid token and campaign' do
      it 'queues post confirm message' do
        Sqs.expects(:send_message)
        get(:create, :token => @gamer.confirmation_token, :content => 'confirm_only')
      end
    end
    context 'with valid token only' do
      it 'redirects to url without tracking params' do
        get(:create, :token => @gamer.confirmation_token)
        response.code.should == "302"
        response.session[:flash][:notice].should == 'Email address confirmed.'
        response.redirected_to.should == games_root_path
      end
    end
    context 'with invalid token' do
      it 'redirects with flash error' do
        get(:create, :token => 'bad_token')
        response.code.should == "302"
        response.session[:flash][:error].should == 'Unable to confirm email address.'
        response.redirected_to.should == games_root_path
      end
    end
  end
end
