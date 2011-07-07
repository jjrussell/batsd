class Apsalar
  ACCEPTED_PLATFORMS = %w(iphone android)
  def self.ping_rewarded_install(click)
    advertiser_app = App.find_by_id(click.advertiser_app_id, :include => [:partner])
    if advertiser_app.present? && ACCEPTED_PLATFORMS.include?(advertiser_app.platform) && advertiser_app.partner.apsalar_sharing_adv?
      hash = {
        'tp' => advertiser_app.partner.id,
        'taid' => advertiser_app.id,
        'e' => 'install',
        'p' => advertiser_app.platform_name,
        'a' => advertiser_app.store_id,
        'u' => click.udid,
        'i' => click.ip_address || "0.0.0.0",
      }

      hash['h'] = Digest::MD5.hexdigest(hash['tp'] + hash['taid'] + hash['e'] + hash['p'] +
                            hash['a'] + hash['u'] + hash['i'] + APSALAR_SECRET)
      url = APSALAR_EVENT_URL + '?' + hash.to_query
      Downloader.get_with_retry(url)
    end

    publisher_app = App.find_by_id(click.publisher_app_id, :include => [:partner])
    if publisher_app.present? && ACCEPTED_PLATFORMS.include?(publisher_app.platform) && publisher_app.partner.apsalar_sharing_pub?
      hash = {
        'tp' => publisher_app.partner.id,
        'taid' => publisher_app.id,
        'e' => 'redemption',
        'v' => (click.publisher_amount / 100.0).to_s,
        'p' => advertiser_app.platform_name,
        'a' => publisher_app.store_id,
        'u' => click.udid,
        'i' => click.ip_address || "0.0.0.0",
      }

      hash['h'] = Digest::MD5.hexdigest(hash['tp'] + hash['taid'] + hash['e'] + hash['v'] +
                            hash['p'] + hash['a'] + hash['u'] + hash['i'] + APSALAR_SECRET)
      url = APSALAR_EVENT_URL + '?' + hash.to_query
      Downloader.get_with_retry(url)
    end
  end

end
