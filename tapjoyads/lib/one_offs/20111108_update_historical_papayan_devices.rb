class OneOffs
  #dates should be PT
  def self.update_historical_papayan_devices(start_date = Date.parse('2011-05-18'), end_date = Date.yesterday)
    (start_date..end_date).each do |date|
      delta = Benchmark.realtime{ Papaya.update_device_by_date(date) }
      if delta < 60 and date < end_date #api restrict calling for different dates within 1 minute
        sleep 60 - delta
      end
    end
  end
end
