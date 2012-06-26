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
end
