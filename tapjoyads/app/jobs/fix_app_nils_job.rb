class FixAppNils
  def run
    response = SimpledbResource.query('app', 'app_id', "next_run_time is nil", '')
    response.items.each do |item| 
      app_id = item.attributes[0].value
      app = App.new(app_id)
      next_run_time = (Time.now + 1.minutes).to_f.to_s
      app.put('next_run_time', next_run_time)
      app.save
      Rails.logger.info("Added next_run_time to #{app_id} for #{next_run_time}")
    end
  end
end