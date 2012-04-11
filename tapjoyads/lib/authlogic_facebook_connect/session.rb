module AuthlogicFacebookConnect
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end

    module Config
      # * <tt>Default:</tt> :facebook_id
      # * <tt>Accepts:</tt> Symbol
      def facebook_id_field(value = nil)
        rw_config(:facebook_id_field, value, :facebook_id)
      end
      alias_method :facebook_id_field=, :facebook_id_field

      # * <tt>Default:</tt> :fb_access_token
      # * <tt>Accepts:</tt> Symbol
      def fb_access_token_field(value = nil)
        rw_config(:fb_access_token_field, value, :fb_access_token)
      end
      alias_method :fb_access_token_field=, :fb_access_token_field

      # * <tt>Default:</tt> :gamer_profile
      # * <tt>Accepts:</tt> Symbol
      def gamer_profile_field(value = nil)
        rw_config(:gamer_profile_field, value, :gamer_profile)
      end
      alias_method :gamer_profile_field=, :gamer_profile_field

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
        exist_user = facebook_user_class.find(
          :first,
          :conditions => { :gamer_profiles => { :facebook_id => facebook_session.id } },
          :include => :gamer_profile)

        if exist_user
          self.attempted_record = exist_user
        else
          match_user = facebook_user_class.find(:first, :conditions => { :email => facebook_session.email })
          if match_user
            if klass == facebook_user_class
              match_user.send(:"#{gamer_profile_field}").send(:"#{facebook_id_field}=", facebook_session.id)
              match_user.send(:"#{gamer_profile_field}").send(:"#{fb_access_token_field}=", facebook_session.client.access_token)
              match_user.send(:"#{gamer_profile_field}").save
            end

            self.attempted_record = match_user
          else
            errors.add(:facebook, "facebook_no_match")
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

      def facebook_id_field
        self.class.facebook_id_field
      end

      def fb_access_token_field
        self.class.fb_access_token_field
      end

      def gamer_profile_field
        self.class.gamer_profile_field
      end

      def facebook_user_class
        self.class.facebook_user_class
      end
    end
  end
end
