require 'spec_helper'

describe KontagentMailer do
  describe 'accept_email' do
    let(:user) { mock_model(User, :username => 'TestUsername', :email => 'testemail@tapjoy.com') }
    let(:mail) { KontagentMailer.approval(user).deliver }

    #ensure that the subject is correct
    it 'renders the subject' do
      mail.subject.should == 'Kontagent approval - Tapjoy'
    end
 
    #ensure that the receiver is correct
    it 'renders the receiver email' do
      mail.to.should == [user.email]
    end
 
    #ensure that the sender is correct
    it 'renders the sender email' do
      mail.from.should == ['noreply@tapjoy.com']
    end

    #ensure that the username variable appears in the email body
    it 'assigns username' do
      mail.body.encoded.should match(user.username)
    end
  end
end
