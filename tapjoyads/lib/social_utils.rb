module SocialUtils

  class Facebook
    def self.facebook_client(gamer)
      begin
        client = Mogli::Client.new(gamer.fb_access_token) if gamer.fb_access_token
      rescue Exception => e
        raise I18n.t('text.games.generic_issue')
      end
      client || nil
    end

    def self.facebook_query(gamer, query)
      begin
        client = facebook_client(gamer)
        result = client.fql_query(query) if client
      rescue Exception => e
        raise I18n.t('text.games.generic_issue')
      end
      result || nil
    end
  end
end
