require 'spec_helper'

describe ConsoleSecurity::Authentication do
  it { should belong_to :user }
  it { should_not allow_mass_assignment_of :id }
  it { should validate_presence_of :provider }
  it { should validate_presence_of :uid }

  let (:user) { FactoryGirl.create(:typical_user) }
  describe '.for_auth_hash' do
    before :each do
      @uid = user.id.to_s
      @auth_hash = OmniAuth::AuthHash.new({
        :provider => 'tapjoy',
        :uid => @uid,
        :info => { :email => 'spec@tapjoy.com', :first_name => 'Spec', :last_name => 'Smith' },
      })
      subject.stub(:save!)
    end

    it 'searches by provider and uid' do
      collection = double('authlist', :first_or_initialize => subject)

      ConsoleSecurity::Authentication.should_receive(:where).with({:provider => 'tapjoy', :uid => @uid}).and_return(collection)

      ConsoleSecurity::Authentication.for_auth_hash(@auth_hash)
    end

    context "considering user records" do
      before :each do
        authCollection = double('authlist', :first_or_initialize => subject)
        ConsoleSecurity::Authentication.stub(:where).and_return(authCollection)
        userCollection = double('userlist', :first => user)
        User.stub(:where).with({:email => 'spec@tapjoy.com'}).and_return(userCollection)
      end

      it 'assigns the existing user record' do
        ConsoleSecurity::Authentication.for_auth_hash(@auth_hash)
        subject.user_id.should == @uid
      end
    end
  end
end
