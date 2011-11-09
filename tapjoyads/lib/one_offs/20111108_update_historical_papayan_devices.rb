class OneOffs
  #date string should be PDT in the format of '%yyyy-%mm-%dd'
  def self.update_historical_papayan_devices(start_date_str = '2011-05-18', end_date_str = Date.yesterday.to_s(:yyyy_mm_dd))
    updater = Job::MasterUpdatePapayanDeviceController.new
    begin
      start_date = Date.parse start_date_str
      end_date = Date.parse end_date_str
    rescue Exception => e
      puts 'Error parsing dates! '+e
      return
    end
    (start_date...end_date+1).each do |date|
      puts date
      delta = Benchmark.realtime{ updater.index(date.to_s(:yy_mm_dd)) }
      if delta < 60 and date < end_date #api restrict calling for different dates within 1 minute
        sleep 60 - delta
      end
    end
  end
end
