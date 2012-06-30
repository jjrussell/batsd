require 'spec_helper'

describe Games::GamersController do
  before :each do
    activate_authlogic
  end

  describe '#create' do
    before :each do
      @date = 13.years.ago(Time.zone.now.beginning_of_day) - 1.day
      @options = {
        :gamer => {
          :email            => FactoryGirl.generate(:email),
          :password         => FactoryGirl.generate(:name),
          :terms_of_service => '1',
          :birthdate        => @date.to_s
        },
        :default_platforms => {
          :android => '1',
          :ios => '0',
        }
      }
    end

    it 'creates a new gamer' do
      Sqs.should_receive(:send_message).once
      post(:create, @options)

      should_respond_with_json_success(200)
    end

    it 'rejects when under 13 years old' do
      @options[:gamer][:birthdate] = @date + 2.days
      post(:create, @options)

      should_respond_with_json_error(403)
    end

    it 'rejects when under date is invalid' do
      @options[:gamer][:birthdate] = 'blahblahblah'
      post(:create, @options)

      should_respond_with_json_error(403)
    end

    context 'when referrer present' do
      before :each do
        @gamer = FactoryGirl.create(:gamer)

        @partner = FactoryGirl.create(:partner, :id => TAPJOY_PARTNER_ID)
        @invite_offer = FactoryGirl.create(:invite_offer, :partner => @partner)
        @options[:gamer][:email] = 'TEST@test.com'
      end

      context 'when in new format' do
        it 'establishes friendship based on referrer data' do
          @options[:gamer][:referrer] = ObjectEncryptor.encrypt("#{@gamer.id},#{TAPJOY_GAMES_INVITATION_OFFER_ID}")
          post 'create', @options
          @noob = assigns[:gamer]

          Friendship.find("#{@noob.id}.#{@gamer.id}").should be_present
        end
      end

      context 'when in old format' do
        before :each do
          @invitation = FactoryGirl.create(
            :invitation,
            :gamer_id => @gamer.id,
            :external_info => @options[:gamer][:email]
          )
          @options[:gamer][:referrer] = ObjectEncryptor.encrypt("#{@invitation.id},#{TAPJOY_GAMES_INVITATION_OFFER_ID}")
        end

        context 'when gamer exist' do
          before :each do
            post 'create', @options
            @noob = assigns[:gamer]
          end

          it 'establishes friendship based on referrer data' do
            Friendship.find("#{@noob.id}.#{@gamer.id}").should be_present
          end

          it 'updates the status of invite' do
            @invitation.reload
            @invitation.status.should == 1
          end
        end

        context 'when gamer not exist' do
          before :each do
            @gamer_id = @gamer.id
            @gamer.destroy
            post 'create', @options
            @noob = assigns[:gamer]
          end

          it 'does not establish friendship' do
            Friendship.find("#{@noob.id}.#{@gamer_id}").should_not be_present
          end
        end
      end
    end
  end

  describe '#destroy' do
    before :each do
      @gamer = FactoryGirl.create(:gamer)
      @controller.stub(:current_gamer).and_return(@gamer)
    end

    it 'displays confirmation page' do
      get(:confirm_delete)
      response.should be_success
    end

    it 'deactivates gamer' do
      delete(:destroy)

      response.should be_redirect
      (Time.zone.now - @gamer.deactivated_at).should < 60
    end
  end

  describe '#create_account_for_offer' do
    before :each do
      current_facebook_user = mock('current_facebook_user')
      current_facebook_client = mock('current_facebook_client')
      click = mock("click")

      @controller.stub(:current_facebook_user).and_return(current_facebook_user)
      current_facebook_user.stub(:fetch).and_return(current_facebook_user)
      current_facebook_user.stub(:email).and_return("email@test.com")
      current_facebook_user.stub(:birthday).and_return("1900-01-01")
      current_facebook_user.stub(:name).and_return("name")
      current_facebook_user.stub(:gender).and_return("female")
      current_facebook_user.stub(:id).and_return("id")
      current_facebook_user.stub(:client).and_return(current_facebook_client)
      current_facebook_client.stub(:access_token).and_return("token")

      Click.stub(:new).and_return(click)
      click.stub(:rewardable?).and_return(true)
      click.stub(:key).and_return('click_key')
      click.stub(:udid).and_return('udid')
      click.stub(:device_name).and_return('device_name')
    end

    context 'when gamer already exist' do
      before :each do
        @gamer = Factory(:gamer)
        @gamer.gamer_profile.update_attributes(:facebook_id => 'id')
        get(:create_account_for_offer, :udid => 'udid')
      end

      it 'returns true' do
        JSON.parse(response.body)['success'].should be_true
      end

      it 'logs in this existing gamer' do
        request.session['gamer_credentials_id'].should == @gamer.id
      end

      it 'connects device with the existing gamer' do
        @gamer.devices.include?(GamerDevice.find_by_gamer_id_and_device_id(@gamer.id, 'udid')).should be_true
      end

      it 'set last run time for LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID offer' do
        Device.find('udid').has_app?(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID).should be_true
      end
    end

    context 'when matching gamer exist' do
      before :each do
        @gamer = Factory(:gamer, :email => "email@test.com")
        @gamer.gamer_profile.update_attributes(:facebook_id => nil, :gamer => @gamer)
        get(:create_account_for_offer, :udid => 'udid')
      end

      it 'returns true' do
        JSON.parse(response.body)['success'].should be_true
      end

      it 'logs in this matching gamer' do
        request.session['gamer_credentials_id'].should == @gamer.id
      end

      it 'updates the matching gamer with facebook id' do
        @gamer.reload
        @gamer.gamer_profile.facebook_id.should == 'id'
      end

      it 'connects device with the matching gamer' do
        @gamer.devices.include?(GamerDevice.find_by_gamer_id_and_device_id(@gamer.id, 'udid')).should be_true
      end

      it 'set last run time for LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID offer' do
        Device.find('udid').has_app?(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID).should be_true
      end
    end

    context 'when gamer not exist' do
      before :each do
        get(:create_account_for_offer, :udid => 'udid')
      end

      it 'returns true' do
        JSON.parse(response.body)['success'].should be_true
      end

      it 'sets new gamer email to be facebook email' do
        new_gamer = Gamer.find_by_id(request.session['gamer_credentials_id'])
        new_gamer.email.should == 'email@test.com'
      end

      it 'set new gamer facebook_id to be facebook id' do
        new_gamer = Gamer.find_by_id(request.session['gamer_credentials_id'])
        new_gamer.facebook_id.should == 'id'
      end

      it 'logs in this new gamer' do
        new_gamer = Gamer.find(
          :first,
          :conditions => { :email => 'email@test.com', :gamer_profiles => { :facebook_id => 'id' } },
          :include => :gamer_profile)
        request.session['gamer_credentials_id'].should == new_gamer.id
      end

      it 'connects device with the new gamer' do
        new_gamer = Gamer.find_by_id(request.session['gamer_credentials_id'])
        new_gamer.devices.include?(GamerDevice.find_by_gamer_id_and_device_id(new_gamer.id, 'udid')).should be_true
      end

      it 'set last run time for LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID offer' do
        Device.find('udid').has_app?(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID).should be_true
      end
    end
  end
end
