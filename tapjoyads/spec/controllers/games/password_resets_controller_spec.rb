require 'spec/spec_helper'

describe Games::PasswordResetsController do
  describe 'going to /password-reset' do
    describe 'using GET' do
      it 'renders new' do
        path = { :controller => 'games/password_resets', :action => 'new' }
        { :get => "/games/password-reset" }.should route_to path
      end
    end

    describe 'using POST' do
      it 'renders create' do
        path = { :controller => 'games/password_resets', :action => 'create' }
        { :post => "/games/password_resets" }.should route_to path
      end

      it 'sends email' do
        gamer = Factory(:gamer)
        GamesMailer.expects(:deliver_password_reset).once
        post(:create, :email => gamer.email)

        response.should render_template("new")
      end
    end
  end
end
