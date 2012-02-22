class PapayaAPIError < RuntimeError; end
class Papaya
  def self.queue_daily_update_devices_jobs
    date_str = Date.yesterday.to_s(:yy_mm_dd)
    Sqs.send_message(QueueNames::UPDATE_PAPAYA_DEVICES, date_str)
  end

  def self.queue_daily_update_user_count_jobs
    Sqs.send_message(QueueNames::UPDATE_PAPAYA_USER_COUNT, 'run')
  end

  def self.update_devices_by_date(date_str)
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
        raise PapayaAPIError.new("invalid number from Papaya : #{package_name} = #{user_count.inspect} -> #{user_count.class}")
        next
      end
      apps = AppMetadata.find_all_by_store_id(package_name)
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
        raise PapayaAPIError.new("Error getting Papaya data: #{e}, url = #{url}")
        return []
      end
    end

    begin
      message = Base64.decode64(response.body)
      json_string = SymmetricCrypto.decrypt(message, PAPAYA_SECRET, 'AES-128-ECB')
      papaya_data = JSON.load(json_string)
    rescue Exception => e
      raise PapayaAPIError.new("Error parsing Papaya data: #{e}")
      return []
    end

    if papaya_data.blank?
      raise PapayaAPIError.new("Papaya data is empty")
    end
    papaya_data
  end
end
