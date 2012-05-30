module AuthlogicFacebookConnect
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end

    module Config
      # * <tt>Default:</tt> klass
      # * <tt>Accepts:</tt> Class
      def facebook_user_class(value = nil)
        rw_config(:facebook_user_class, value, klass)
      end
      alias_method :facebook_user_class=, :facebook_user_class
    end

    module Methods
      def self.included(klass)
        klass.class_eval do
          validate :validate_by_facebook_connect, :if => :authenticating_with_facebook_connect?
        end

        def credentials=(value)
          # TODO: Is there a nicer way to tell Authlogic that we don't have any credentials than this?
          values = [:facebook_connect]
          super
        end
      end

      def validate_by_facebook_connect
        facebook_session = controller.current_facebook_user.fetch
        existing_user = facebook_user_class.includes(:gamer_profile).where(:gamer_profiles => { :facebook_id => facebook_session.id }).first

        if existing_user
          self.attempted_record = existing_user
        else
          matching_user = facebook_user_class.where(:email => facebook_session.email).first
          if matching_user
            if klass == facebook_user_class
              attributes = {
                :facebook_id => facebook_session.id,
                :fb_access_token => facebook_session.client.access_token
              }
              if matching_user.gamer_profile
                matching_user.gamer_profile.update_attributes(attributes)
              else
                gamer_profile = GamerProfile.new(attributes)
                matching_user.gamer_profile = gamer_profile
                matching_user.save
              end
            end

            self.attempted_record = matching_user
          else
            unless UiConfig.is_fb_signup_hidden
              begin
                new_user = klass.new

                if klass == facebook_user_class
                  new_gamer_profile = GamerProfile.new(
                    :birthdate       => facebook_session.birthday,
                    :nickname        => facebook_session.name,
                    :gender          => facebook_session.gender,
                    :facebook_id     => facebook_session.id,
                    :fb_access_token => facebook_session.client.access_token
                  )
                  new_user.gamer_profile = new_gamer_profile
                end

                new_user.before_connect(facebook_session) if new_user.respond_to?(:before_connect)

                new_user.save!

                self.attempted_record = new_user
              rescue Exception => e
                errors.add(:base, I18n.t('error_messages.facebooker_session_expired',
                  :default => "Your Facebook Connect session has expired, please reconnect."))
              end
            end
          end
        end
      end

      def authenticating_with_facebook_connect?
        begin
          attempted_record.nil? && errors.empty? && controller.current_facebook_user
        rescue Exception => e
          false
        end
      end

      private

      def facebook_user_class
        self.class.facebook_user_class
      end
    end
  end
end

Authlogic::Session::Base.send(:include, AuthlogicFacebookConnect::Session)
