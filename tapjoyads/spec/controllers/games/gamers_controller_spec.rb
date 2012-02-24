require 'spec/spec_helper'

describe Games::GamersController do
  before :each do
    activate_authlogic
  end

  describe '#create' do
    before :each do
      @date = 13.years.ago(Time.zone.now.beginning_of_day) - 1.day
      @options = {
        :gamer => {
          :email            => Factory.next(:email),
          :password         => Factory.next(:name),
          :terms_of_service => '1',
        },
        :date => {
          :year  => @date.year,
          :month => @date.month,
          :day   => @date.day,
        },
        :default_platforms => {
          :android => '1',
          :ios => '0',
        }
      }
    end

    it 'creates a new gamer' do
      Sqs.expects(:send_message).once
      post(:create, @options)

      should_respond_with_json_success(200)
    end

    it 'rejects when under 13 years old' do
      @date += 2.days
      @options[:date] = {
        :year  => @date.year,
        :month => @date.month,
        :day   => @date.day,
      }
      post(:create, @options)

      should_respond_with_json_error(403)
    end

    it 'rejects when under date is invalid' do
      @options[:date] = {
        :year  => @date.year,
        :month => 11,
        :day   => 31,
      }
      post(:create, @options)

      should_respond_with_json_error(403)
    end

    context 'when referrer present' do
      before :each do
        @gamer = Factory(:gamer)

        @partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
        @invite_offer = Factory(:invite_offer, :partner => @partner)
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
          @invitation = Factory(
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
      @gamer = Factory(:gamer)
      @controller.stubs(:current_gamer).returns(@gamer)
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
