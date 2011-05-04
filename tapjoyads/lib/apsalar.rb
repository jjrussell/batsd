class Apsalar

  def self.ping_rewarded_install(click)
    advertiser_app = App.find_by_id(click.advertiser_app_id, :include => [:partner])
    if advertiser_app.present?
      hash = {
        'tp' => advertiser_app.partner.id,
        'taid' => advertiser_app.id,
        'e' => 'install',
        'p' => advertiser_app.is_android? ? 'Android' : 'iOS',
        'a' => advertiser_app.store_id,
        'u' => click.udid,
        'i' => click.ip_address,
      }

      hash['h'] = Digest::MD5.hexdigest(hash['tp'] + hash['taid'] + hash['e'] + hash['p'] +
                            hash['a'] + hash['u'] + hash['i'] + APSALAR_SECRET)
      Downloader.get_with_retry(APSALAR_EVENT_URL + '?' + hash.to_query)
    end

    publisher_app = App.find_by_id(click.publisher_app_id, :include => [:partner])
    if publisher_app.present?
      hash = {
        'tp' => publisher_app.partner.id,
        'taid' => publisher_app.id,
        'e' => 'redemption',
        'v' => (click.publisher_amount / 100.0).to_s,
        'p' => publisher_app.is_android? ? 'Android' : 'iOS',
        'a' => publisher_app.store_id,
        'u' => click.udid,
        'i' => click.ip_address,
      }

      hash['h'] = Digest::MD5.hexdigest(hash['tp'] + hash['taid'] + hash['e'] + hash['v'] +
                            hash['p'] + hash['a'] + hash['u'] + hash['i'] + APSALAR_SECRET)
      Downloader.get_with_retry(APSALAR_EVENT_URL + '?' + hash.to_query)
    end
  end

end
