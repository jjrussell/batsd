class Papaya
  def self.update_device_by_date(date)
    date_str = date.to_s(:yy_mm_dd)
    url = "#{PAPAYA_API_URL}/imeiapi/udid_list?date=#{date_str}"
    papaya_data = get_papaya_data(url)

    papaya_data.each do |id|
      #probably needs to add filter to invalid udids later, have seen "0000000000", "0", and sometimes a udid followed by '/0 2'. Other 99.9% seems valid though
      device = Device.new(:key => id.downcase)
      unless device.is_papayan?
        device.is_papayan = true
        device.serial_save
      end
    end
  end

  def self.update_apps
    url = "#{PAPAYA_API_URL}/imeiapi/app_list"
    papaya_data = get_papaya_data(url)

    papaya_data.each do |package_name, user_count|
      unless user_count.is_a?(Integer)
        Notifier.alert_new_relic(PapayaAPIError, "invalid number from Papaya : #{package_name} = #{user_count}")
        next
      end
      apps = App.find_all_by_store_id(package_name)
      apps.each do |app|
        if app.papaya_user_count != user_count
          app.papaya_user_count = user_count
          app.save
        end
      end
    end
  end

  def self.get_papaya_data(url)
    retries = 5
    begin
      response = Downloader.get_strict(url, {:timeout => 30})
    rescue Exception => e
      if retries > 0
        retries -= 1
        sleep 5
        retry
      else
        Notifier.alert_new_relic(PapayaAPIError, "Error getting Papaya data: #{e}, url = #{url}")
        return []
      end
    end

    begin
      message = Base64.decode64(response.body)
      json_string = SymmetricCrypto.decrypt(message, PAPAYA_SECRET, 'AES-128-ECB')
      papaya_data = JSON.load(json_string)
    rescue Exception => e
      Notifier.alert_new_relic(PapayaAPIError, "Error parsing Papaya data: #{e}")
      return []
    end

    if papaya_data.blank?
      Notifier.alert_new_relic(PapayaAPIError, "Papaya data is empty")
    end
    papaya_data
  end
end
