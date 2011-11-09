class OneOffs
  def self.update_historical_papayan_devices(start_date_str = '2011-05-18', end_date_str = (Time.now - 1.day).strftime("%Y-%m-%d"))
    updater = Job::MasterUpdatePapayanDeviceController.new
    begin
      date = Date.parse start_date_str
      end_date = Date.parse end_date_str
    rescue Exception => e
      puts 'Error parsing dates! '+e
      return
    end
    while date <= end_date
      puts date
      t1 = Time.now
      updater.index(date.strftime("%y-%m-%d"))
      delta = Time.now - t1
      if delta < 60  #api restrict calling for different dates within 1 minute
        sleep 60 - delta
      end
      date += 1.day
    end
  end
end
