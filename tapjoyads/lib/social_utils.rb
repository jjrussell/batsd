module SocialUtils

  class Facebook
    def self.facebook_client(gamer)
      begin
        client = Mogli::Client.new(gamer.fb_access_token) if gamer.fb_access_token
      rescue Exception => e
        raise I18n.t('text.games.generic_issue')
      end
      client
    end

    def self.facebook_query(gamer, query)
      begin
        client = facebook_client(gamer)
        result = client.fql_query(query)
        raise if result.is_a?(Hash) && result.key?('error_code')
      rescue Exception => e
        raise I18n.t('text.games.generic_issue')
      end
      result
    end

    def self.friends_for(gamer)
      Rails.cache.fetch("facebook_friends.#{gamer.id}", :expires_in => 4.hour) do
        query = "SELECT uid, name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())"
        friends = SocialUtils::Facebook.facebook_query(gamer, query) || {}

        friends.map do |fb_friend|
          friend = Gamer.includes(:gamer_profile).where(:gamer_profiles => { :facebook_id => fb_friend['uid'].to_s }).first

          {
            :id            => fb_friend['uid'].to_s,
            :name          => fb_friend['name'],
            :is_tjm_gamer  => friend.present?,
            :is_tjm_friend => (friend.present? && gamer.friend_of?(friend))
          }
        end
      end
    end
  end
end
