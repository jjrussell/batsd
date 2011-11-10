class Job::MasterUpdatePapayanDeviceController < Job::JobController
  def index(date_str = nil)
    date_str = Date.yesterday.to_s(:yy_mm_dd) unless date_str.present?
    url = "#{PAPAYA_API_URL}/imeiapi/udid_list?date=#{date_str}"
    retries = 5
    begin
      response = Downloader.get_strict(url, {:timeout => 30})
    rescue Exception => e
      if retries > 0
        retries -= 1
        sleep 5
        retry
      else
        Notifier.alert_new_relic(UpdatePapayanDeviceError, "Error getting Papaya deveice udids for date #{date_str}: #{e}")
        return
      end
    end

    begin
      message = Base64.decode64(response.body)
      json_string = SymmetricCrypto.decrypt(message, PAPAYA_SECRET, 'AES-128-ECB')
      parsed_json = JSON.load(json_string)
    rescue Exception => e
      Notifier.alert_new_relic(UpdatePapayanDeviceError, "Error parsing Papaya udid list for date #{date_str}: #{e}")
      return
    end

    if parsed_json.length == 0
      Notifier.alert_new_relic(UpdatePapayanDeviceError, "Papaya udid list is empty for date #{date_str}, please make sure the date format is correct")
      return
    end

    parsed_json.each do |id|
      #probably needs to add filter to invalid udids later, have seen "0000000000", "0", and sometimes a udid followed by '/0 2'. Other 99.9% seems valid though
      device = Device.new(:key => id.downcase)
      device.is_papayan = true
      device.serial_save
    end
    puts parsed_json.length
  end
end
